import pytest
import os
from unittest.mock import patch, MagicMock


@pytest.fixture(autouse=True, scope="session")
def set_env_vars():
    # Backup original environment variables
    original_env = dict(os.environ)

    os.environ["WAFACLNAME"] = "test-waf-id"
    os.environ["WAFACLID"] = "test-waf-acl"
    os.environ["WAFRULEPRI"] = "0"
    os.environ["HEADERNAME"] = "x-origin-verify"
    os.environ["APPLICATION"] = "test-app"
    os.environ["ENVIRONMENT"] = "test"
    os.environ["ROLEARN"] = "arn:aws:iam::123456789012:role/test-role"
    os.environ["DISTROIDLIST"] = "example.com,example2.com"

    # Yield control back to the tests
    yield

    os.environ.clear()
    os.environ.update(original_env)

class TestRotateSecretLambda:

    @patch("boto3.client")
    def test_get_cloudfront_session(self, mock_boto_client):
        from rotate_secret_lambda import get_cloudfront_session

        mock_sts = MagicMock()
        mock_boto_client.return_value = mock_sts
        mock_credentials = {
            "Credentials": {
                "AccessKeyId": "testAccessKey",
                "SecretAccessKey": "testSecret",
                "SessionToken": "testSession",
            }
        }
        mock_sts.assume_role.return_value = mock_credentials
        
        session = get_cloudfront_session()
        
        mock_sts.assume_role.assert_called_once_with(
            RoleArn=os.environ["ROLEARN"], RoleSessionName="rotation_session"
        )

        mock_boto_client.assert_called_with(
            "cloudfront",
            aws_access_key_id="testAccessKey",
            aws_secret_access_key="testSecret",
            aws_session_token="testSession",
        )

        assert session is not None

    @patch("boto3.client")
    @patch("rotate_secret_lambda.get_cloudfront_session")
    def test_get_distro_list(self, mock_cloudfront_session, mock_boto_client):
        from rotate_secret_lambda import get_distro_list

        mock_cloudfront = MagicMock()
        mock_cloudfront_session.return_value = mock_cloudfront

        # paginator response
        mock_cloudfront.get_paginator.return_value.paginate.return_value = [
            {
                "DistributionList": {
                    "Items": [
                        {
                            "Id": "dist123",
                            "ARN": "arn:aws:cloudfront::exampledistribution",
                            "Status": "Deployed",
                            "LastModifiedTime": "2022-01-01T00:00:00Z",
                            "DomainName": "exampledistribution.cloudfront.net",
                            "Aliases": {"Quantity": 1, "Items": ["example.com"]},
                            "Origins": {
                                "Quantity": 1,
                                "Items": [
                                    {
                                        "Id": "origin1",
                                        "DomainName": "internal.example.com",
                                    }
                                ],
                            },
                            "Enabled": True,
                        }
                    ],
                    "Quantity": 1,
                }
            }
        ]

        distros = get_distro_list()
        assert len(distros) == 1
        assert distros[0]["Id"] == "dist123"
        assert distros[0]["Origin"] == "internal.example.com"
        assert distros[0]["Domain"] == "example.com"

    @patch("boto3.client")
    def test_get_wafacl_returns_rules(self, mock_boto_client):
        from rotate_secret_lambda import get_wafacl

        mock_wafv2 = MagicMock()
        mock_boto_client.return_value = mock_wafv2

        mock_wafv2.get_web_acl.return_value = {
            "LockToken": "a1b2c3d4-5678-90ab-cdef-1234567890ab",
            "WebACL": {
                "Rules": [
                    {
                        "Action": "ALLOW",
                        "Priority": 0,
                        "Type": "REGULAR",
                    }
                ],
                "Name": os.environ["WAFACLNAME"],
                "WebACLId": os.environ["WAFACLID"],
            }
        }

        response = get_wafacl()

        mock_wafv2.get_web_acl.assert_called_once_with(
            Name=os.environ["WAFACLNAME"], Scope="REGIONAL", Id=os.environ["WAFACLID"]
        )
        
        assert "LockToken" in response
        assert "Rules" in response["WebACL"]
        assert response["WebACL"]["Name"] == os.environ["WAFACLNAME"]
        assert response["WebACL"]["WebACLId"] == os.environ["WAFACLID"]


    @patch("boto3.client")
    @patch("rotate_secret_lambda.get_wafacl")
    def test_update_wafacl_creates_and_updates_waf_rule(self, mock_get_wafacl, mock_boto_client):
        from rotate_secret_lambda import update_wafacl
        
        application = os.environ["APPLICATION"]
        environment = os.environ["ENVIRONMENT"]
        new_secret = "NEW"
        previous_secret = "PREVIOUS"
        
        mock_wafv2 = MagicMock()
        mock_boto_client.return_value = mock_wafv2
        mock_get_wafacl.return_value = {
            'LockToken': 'test-lock-token',
            'WebACL': {
                'Rules': [
                    {
                        'Name': 'DifferentPriorityRule',
                        'Priority': 5,
                        'Action': 'BLOCK',
                    },
                    {
                        'Name': f"{application}{environment}XOriginVerify",
                        'Priority': int(os.environ["WAFRULEPRI"]),
                        'Action': 'ALLOW',
                    },
                ]
            }
        }

        update_wafacl(new_secret, previous_secret)

        expected_new_waf_rules = [
            {
                'Name': f"{application}{environment}XOriginVerify",
                'Priority': int(os.environ["WAFRULEPRI"]),
                'Action': {
                    'Allow': {}
                },
                'VisibilityConfig': {
                    'SampledRequestsEnabled': True,
                    'CloudWatchMetricsEnabled': True,
                    'MetricName': f"{application}-{environment}-XOriginVerify"
                },
                'Statement': {
                    'OrStatement': {
                        'Statements': [
                            {
                                'ByteMatchStatement': {
                                    'FieldToMatch': {
                                        'SingleHeader': {
                                            'Name': os.environ["HEADERNAME"]
                                        }
                                    },
                                    'PositionalConstraint': 'EXACTLY',
                                    'SearchString': new_secret,
                                    'TextTransformations': [
                                        {
                                            'Type': 'NONE',
                                            'Priority': 0
                                        }
                                    ]
                                }
                            },
                            {
                                'ByteMatchStatement': {
                                    'FieldToMatch': {
                                        'SingleHeader': {
                                            'Name': os.environ["HEADERNAME"]
                                        }
                                    },
                                    'PositionalConstraint': 'EXACTLY',
                                    'SearchString': previous_secret,
                                    'TextTransformations': [
                                        {
                                            'Type': 'NONE',
                                            'Priority': 0
                                        }
                                    ]
                                }
                            }
                        ]
                    }
                }
            },
            {
                'Name': 'DifferentPriorityRule',
                'Priority': 5,
                'Action': 'BLOCK',
            }
        ]

        mock_wafv2.update_web_acl.assert_called_once_with(
            Name=os.environ["WAFACLNAME"],
            Scope='REGIONAL',
            Id=os.environ["WAFACLID"],
            DefaultAction={'Block': {}},
            Description='CloudFront Origin Verify',
            LockToken='test-lock-token',
            VisibilityConfig={
                'SampledRequestsEnabled': True,
                'CloudWatchMetricsEnabled': True,
                'MetricName': f"{application}-{environment}-XOriginVerify"
            },
            Rules=expected_new_waf_rules
        )
