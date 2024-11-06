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


@patch.dict(os.environ, {"WAFACLNAME": "test-waf-id", "WAFACLID": "test-waf-acl"})
class TestRotateSecretLambda:

    @patch("boto3.client")
    def test_get_cloudfront_session(self, mock_boto_client):
        from rotate_secret_lambda import get_cloudfront_session

        mock_sts = MagicMock()
        mock_boto_client.return_value = mock_sts
        mock_sts.assume_role.return_value = {
            "Credentials": {
                "AccessKeyId": "testAccessKey",
                "SecretAccessKey": "testSecret",
                "SessionToken": "testSession",
            }
        }

        session = get_cloudfront_session()
        mock_sts.assume_role.assert_called_once_with(
            RoleArn=os.environ["ROLEARN"], RoleSessionName="rotation_session"
        )

        mock_boto_client.assert_any_call(
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
    def test_get_wafacl(self, mock_boto_client):
        from rotate_secret_lambda import get_wafacl

        mock_wafv2 = MagicMock()
        mock_boto_client.return_value = mock_wafv2
        # mock_wafv2.get_web_acl.return_value = {"WebACL": {"Rules": []}, "'WebACLArn'": "lockToken123"}

        mock_wafv2.get_web_acl.return_value = {
            "WebACL": {
                "Rules": [
                    {
                        "RuleId": "rule123",
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
        assert "WebACL" in response
        assert response["WebACL"]["Name"] == os.environ["WAFACLNAME"]
        assert response["WebACL"]["WebACLId"] == os.environ["WAFACLID"]

    @patch("boto3.client")
    def test_update_wafacl(self, mock_boto_client):
        from rotate_secret_lambda import update_wafacl

        mock_waf = MagicMock()
        mock_boto_client.return_value = mock_waf
        mock_waf.update_web_acl.return_value = {"Summary": "success"}

        update_wafacl("new_secret", "old_secret")
        mock_waf.update_web_acl.assert_called_once()

        assert mock_waf.update_web_acl.return_value["Summary"] == "success"
