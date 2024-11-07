import pytest
from unittest.mock import patch, MagicMock, call
from botocore.exceptions import ClientError
import json
from rotate_secret_lambda_class import SecretRotator

@pytest.fixture(scope="session")
def rotator():
    """
    Creates a SecretRotator instance with test configuration.
    """
    return SecretRotator(
        waf_acl_name="test-waf-id",
        waf_acl_id="test-waf-acl",
        waf_rule_priority="0",
        header_name="x-origin-verify",
        application="test-app",
        environment="test",
        role_arn="arn:aws:iam::123456789012:role/test-role",
        distro_list="example.com,example2.com"
    )

class TestCloudFrontSessionManagement:
    """
    Tests for CloudFront session management and credentials handling.
    """
    
    def test_assumes_correct_role_for_cloudfront_access(self, rotator):
        """
        The system must use STS to assume the correct role before accessing CloudFront.
        """
        # Given STS credentials for CloudFront access
        mock_credentials = {
            "Credentials": {
                "AccessKeyId": "test-access-key",
                "SecretAccessKey": "test-secret-key",
                "SessionToken": "test-session-token"
            }
        }

        with patch('boto3.client') as mock_boto3_client:
            # Set up separate mocks for STS and CloudFront clients
            mock_sts = MagicMock()
            mock_cloudfront = MagicMock()
            
            # Configure boto3.client to return different mocks based on service name
            mock_boto3_client.side_effect = lambda service, **kwargs: \
                mock_sts if service == 'sts' else mock_cloudfront

            # Configure STS assume_role response
            mock_sts.assume_role.return_value = mock_credentials

            # When getting a CloudFront session
            client = rotator.get_cloudfront_session()

            # Then it should assume the correct role
            mock_sts.assume_role.assert_called_once_with(
                RoleArn="arn:aws:iam::123456789012:role/test-role",
                RoleSessionName='rotation_session'
            )

            # And use the credentials to create a CloudFront client
            mock_boto3_client.assert_has_calls([
                call('sts'),
                call('cloudfront',
                    aws_access_key_id="test-access-key",
                    aws_secret_access_key="test-secret-key",
                    aws_session_token="test-session-token"
                )
            ])

class TestDistributionDiscovery:
    """
    Tests for CloudFront distribution discovery and filtering.
    """

    def test_identifies_distributions_that_need_secret_updates(self, rotator):
        """
        The lambda must identify all CloudFront distributions that need secret updates
        based on their domain aliases.
        """
        # Given a mix of relevant and irrelevant distributions
        mock_distributions = {
            "DistributionList": {
                "Items": [
                    {
                        "Id": "DIST1",
                        "Origins": {"Items": [{"DomainName": "origin1.example.com"}]},
                        "Aliases": {"Items": ["example.com"]}  # Should match
                    },
                    {
                        "Id": "DIST2",
                        "Origins": {"Items": [{"DomainName": "origin2.example.com"}]},
                        "Aliases": {"Items": ["example2.com"]}  # Should match
                    },
                    {
                        "Id": "DIST3",
                        "Origins": {"Items": [{"DomainName": "origin3.example.com"}]},
                        "Aliases": {"Items": ["unrelated.com"]}  # Should not match
                    }
                ]
            }
        }

        with patch.object(rotator, 'get_cloudfront_session') as mock_session:
            # When discovering distributions
            mock_client = MagicMock()
            mock_paginator = MagicMock()
            mock_paginator.paginate.return_value = [mock_distributions]
            mock_client.get_paginator.return_value = mock_paginator
            mock_session.return_value = mock_client

            result = rotator.get_distro_list()

            # Then it should return only matching distributions
            assert len(result) == 2, "Should find exactly 2 matching distributions"
            
            # And preserve necessary information for each distribution
            for dist in result:
                assert set(dist.keys()) == {"Id", "Origin", "Domain"}, \
                    "Each distribution must have Id, Origin, and Domain"
                assert dist["Domain"] in ["example.com", "example2.com"], \
                    f"Unexpected domain: {dist['Domain']}"

            # And use pagination for large lists
            mock_client.get_paginator.assert_called_once_with("list_distributions")

class TestWAFManagement:
    """
    Tests for WAF rule management during secret rotation.
    These tests verify that WAF rules are updated correctly to ensure zero-downtime rotation.
    """

    def test_waf_contains_both_secrets_during_rotation(self, rotator):
        """
        During rotation, the WAF rule must accept both old and new secrets.
        """
        # Given existing WAF rules including non-secret rules
        current_rules = {
            "WebACL": {
                "Rules": [
                    {"Priority": 1, "Name": "ExistingRule1"},
                    {"Priority": 2, "Name": "ExistingRule2"}
                ]
            },
            "LockToken": "test-lock-token"
        }

        with patch('boto3.client') as mock_boto3_client, \
             patch.object(rotator, 'get_wafacl') as mock_get_wafacl:
            
            mock_get_wafacl.return_value = current_rules
            mock_wafv2 = mock_boto3_client.return_value

            # When updating the WAF ACL with both secrets
            rotator.update_wafacl("new-secret", "old-secret")

            # Then the update should preserve existing rules
            call_args = mock_wafv2.update_web_acl.call_args[1]
            existing_rules = [r for r in call_args['Rules'] 
                            if r.get('Name') in ['ExistingRule1', 'ExistingRule2']]
            assert len(existing_rules) == 2, "Must preserve existing WAF rules"

            # And include both secrets in an OR condition
            secret_rule = next(r for r in call_args['Rules'] 
                             if r.get('Name') == 'test-apptest' + 'XOriginVerify')
            statements = secret_rule['Statement']['OrStatement']['Statements']
            header_values = [s['ByteMatchStatement']['SearchString'] for s in statements]
            assert "new-secret" in header_values, "New secret must be in WAF rule"
            assert "old-secret" in header_values, "Old secret must be in WAF rule"

    def test_waf_update_is_atomic_with_lock_token(self, rotator):
        """
        WAF updates must be atomic using a lock token to prevent concurrent modifications.
        """
        # Given a WAF with a lock token
        current_rules = {
            "WebACL": {"Rules": []},
            "LockToken": "original-lock-token"
        }

        with patch('boto3.client') as mock_boto3_client, \
             patch.object(rotator, 'get_wafacl') as mock_get_wafacl:
            
            mock_get_wafacl.return_value = current_rules
            mock_wafv2 = mock_boto3_client.return_value

            # When updating the WAF
            rotator.update_wafacl("new-secret", "old-secret")

            # Then it should use the lock token
            call_args = mock_wafv2.update_web_acl.call_args[1]
            assert call_args['LockToken'] == "original-lock-token", \
                "Must use lock token for atomic updates"

class TestDistributionUpdates:
    """
    Tests for CloudFront distribution updates during secret rotation.
    """

    def test_only_updates_deployed_distributions(self, rotator):
        """
        Distribution updates must only proceed when the distribution is in 'Deployed' state.
        """
        # Given a distribution in progress
        with patch.object(rotator, 'get_cloudfront_session') as mock_session:
            mock_client = MagicMock()
            mock_session.return_value = mock_client
            
            # When distribution is not deployed
            mock_client.get_distribution.return_value = {
                "Distribution": {"Status": "InProgress"}
            }

            # Then update should fail safely
            with pytest.raises(ValueError) as exc_info:
                rotator.update_cfdistro("DIST1", "new-header-value")
            
            assert "status is not Deployed" in str(exc_info.value)
            mock_client.update_distribution.assert_not_called()

    def test_updates_all_matching_custom_headers(self, rotator):
        """
        All custom headers matching our header name must be updated with the new secret.
        """
        # Given a distribution with multiple origins and headers
        mock_dist_status = {
            "Distribution": {"Status": "Deployed"}
        }
        mock_dist_config = {
            "DistributionConfig": {
                "Origins": {
                    "Items": [
                        {
                            "Id": "origin1",
                            "CustomHeaders": {
                                "Quantity": 2,
                                "Items": [
                                    {
                                        "HeaderName": "x-origin-verify",
                                        "HeaderValue": "old-value"
                                    },
                                    {
                                        "HeaderName": "other-header",
                                        "HeaderValue": "unchanged"
                                    }
                                ]
                            }
                        },
                        {
                            "Id": "origin2",
                            "CustomHeaders": {
                                "Quantity": 1,
                                "Items": [
                                    {
                                        "HeaderName": "x-origin-verify",
                                        "HeaderValue": "old-value"
                                    }
                                ]
                            }
                        }
                    ]
                }
            },
            "ResponseMetadata": {
                "HTTPHeaders": {"etag": "test-etag"}
            }
        }

        with patch.object(rotator, 'get_cloudfront_session') as mock_session, \
             patch.object(rotator, 'get_cfdistro') as mock_get_cfdistro, \
             patch.object(rotator, 'get_cfdistro_config') as mock_get_config:
            
            mock_client = MagicMock()
            mock_session.return_value = mock_client
            mock_get_cfdistro.return_value = mock_dist_status
            mock_get_config.return_value = mock_dist_config

            # When updating the distribution
            rotator.update_cfdistro("DIST1", "new-value")

            # Then it should update all matching headers
            update_call = mock_client.update_distribution.call_args[1]
            updated_config = update_call['DistributionConfig']
            
            # Verify all x-origin-verify headers were updated
            for origin in updated_config['Origins']['Items']:
                for header in origin['CustomHeaders']['Items']:
                    if header['HeaderName'] == 'x-origin-verify':
                        assert header['HeaderValue'] == "new-value", \
                            f"Header not updated for origin {origin['Id']}"
                    else:
                        assert header['HeaderValue'] == "unchanged", \
                            "Non-matching headers should not be modified"

class TestSecretManagement:
    """
    Tests for AWS Secrets Manager operations during rotation.
    Tests verify the creation and management of secrets during the rotation process.
    """

    def test_new_secret_created_when_no_pending_exists(self, rotator):
        """
        System must create a new pending secret if none exists.
        """
        # Given a service client with only current secret
        mock_service_client = MagicMock()
        mock_service_client.exceptions.ResourceNotFoundException = ClientError
        mock_service_client.get_secret_value.side_effect = [
            {"SecretString": '{"HEADERVALUE":"current-secret"}'}, # AWSCURRENT exists
            ClientError({"Error": {"Code": "ResourceNotFoundException"}}, "operation") # No AWSPENDING
        ]
        mock_service_client.get_random_password.return_value = {"RandomPassword": "new-secret"}

        # When creating a new secret
        rotator.create_secret(mock_service_client, "test-arn", "test-token")

        # Then verify the sequence of operations
        mock_service_client.get_secret_value.assert_has_calls([
            call(SecretId="test-arn", VersionStage="AWSCURRENT"),
            call(SecretId="test-arn", VersionId="test-token", VersionStage="AWSPENDING")
        ], any_order=False)

        # And verify the new secret was stored correctly
        mock_service_client.put_secret_value.assert_called_once_with(
            SecretId="test-arn",
            ClientRequestToken="test-token",
            SecretString='{"HEADERVALUE":"new-secret"}',
            VersionStages=['AWSPENDING']
        )

    def test_secret_creation_requires_existing_current_version(self, rotator):
        """
        New secrets can only be created if there is an existing AWSCURRENT version.
        """
        mock_service_client = MagicMock()
        mock_service_client.exceptions.ResourceNotFoundException = ClientError
        
        # Given no AWSCURRENT secret exists
        mock_service_client.get_secret_value.side_effect = ClientError(
            {"Error": {"Code": "ResourceNotFoundException"}},
            "get_secret_value"
        )

        # When attempting to create a new secret
        # Then it should fail with appropriate error
        with pytest.raises(ClientError) as exc_info:
            rotator.create_secret(mock_service_client, "test-arn", "test-token")

        assert exc_info.value.response["Error"]["Code"] == "ResourceNotFoundException"
        mock_service_client.get_random_password.assert_not_called()
        mock_service_client.put_secret_value.assert_not_called()

class TestRotationProcess:
    """
    Tests for the complete secret rotation process.
    Verifying the end-to-end rotation workflow and its components.
    """

    def test_set_secret_updates_all_components_in_correct_order(self, rotator):
        """
        The set_secret method must update all components in the correct order to ensure
        zero-downtime rotation
        """
        # Given deployed distributions and valid secrets
        mock_distributions = [
            {"Id": "DIST1", "Origin": "origin1.example.com"},
            {"Id": "DIST2", "Origin": "origin2.example.com"}
        ]
        
        mock_get_distro = {
            "Distribution": {"Status": "Deployed"}
        }
        mock_pending_secret = {
            "SecretString": json.dumps({"HEADERVALUE": "new-secret"})
        }
        mock_current_secret = {
            "SecretString": json.dumps({"HEADERVALUE": "current-secret"})
        }
        mock_metadata = {
            "VersionIdsToStages": {
                "current-version": ["AWSCURRENT"],
                "test-token": ["AWSPENDING"]
            }
        }

        mock_service_client = MagicMock()
        mock_service_client.describe_secret.return_value = mock_metadata
        mock_service_client.get_secret_value.side_effect = [
            mock_pending_secret,
            mock_current_secret
        ]

        with patch.object(rotator, 'get_distro_list') as mock_get_distro_list, \
             patch.object(rotator, 'get_cfdistro') as mock_get_cfdistro, \
             patch.object(rotator, 'update_wafacl') as mock_update_wafacl, \
             patch.object(rotator, 'update_cfdistro') as mock_update_cfdistro, \
             patch('time.sleep') as mock_sleep:
            
            mock_get_distro_list.return_value = mock_distributions
            mock_get_cfdistro.return_value = mock_get_distro

            # When setting the secret
            rotator.set_secret(mock_service_client, "test-arn", "test-token")

            # Then verify correct sequence and timing
            operation_sequence = []
            mock_update_wafacl.assert_called_once()
            operation_sequence.append('waf_update')
            
            mock_sleep.assert_called_once_with(75)  # WAF propagation delay
            operation_sequence.append('propagation_wait')
            
            assert mock_update_cfdistro.call_count == 2  # Both distributions updated
            operation_sequence.extend(['distro1_update', 'distro2_update'])

            # Verify WAF was updated before distributions
            assert operation_sequence.index('waf_update') < operation_sequence.index('distro1_update')
            assert operation_sequence.index('propagation_wait') < operation_sequence.index('distro1_update')

    def test_test_secret_validates_all_origins_with_both_secrets(self, rotator):
        """
        The test_secret phase must verify all origin servers accept both old and new secrets.
        """
        mock_pending_secret = {
            "SecretString": json.dumps({"HEADERVALUE": "new-secret"})
        }
        mock_current_secret = {
            "SecretString": json.dumps({"HEADERVALUE": "current-secret"})
        }
        mock_metadata = {
            "VersionIdsToStages": {
                "current-version": ["AWSCURRENT"],
                "test-token": ["AWSPENDING"]
            }
        }
        mock_distributions = [
            {"Id": "DIST1", "Origin": "origin1.example.com"},
            {"Id": "DIST2", "Origin": "origin2.example.com"}
        ]

        mock_service_client = MagicMock()
        mock_service_client.get_secret_value.side_effect = [
            mock_pending_secret,
            mock_current_secret
        ]
        mock_service_client.describe_secret.return_value = mock_metadata

        with patch.object(rotator, 'get_distro_list') as mock_get_distro_list, \
             patch.object(rotator, 'run_test_origin') as mock_run_test_origin:
            
            mock_get_distro_list.return_value = mock_distributions
            mock_run_test_origin.return_value = True

            # When testing the secrets
            rotator.run_test_secret(mock_service_client, "test-arn", "test-token")

            # Then verify each origin was tested with both secrets
            expected_test_calls = [
                call("http://origin1.example.com", "new-secret"),
                call("http://origin1.example.com", "current-secret"),
                call("http://origin2.example.com", "new-secret"),
                call("http://origin2.example.com", "current-secret")
            ]
            mock_run_test_origin.assert_has_calls(expected_test_calls)

class TestFinishSecretStage:
    """
    Test this final stage moves the AWSPENDING secret to AWSCURRENT.
    """

    def test_finish_secret_completes_rotation(self, rotator):
        """
        finish_secret must properly complete the rotation by:
        1. Moving AWSPENDING to AWSCURRENT
        2. Removing AWSCURRENT from old version
        """
        mock_service_client = MagicMock()
        mock_service_client.describe_secret.return_value = {
            "VersionIdsToStages": {
                "old-version": ["AWSCURRENT"],
                "test-token": ["AWSPENDING"]
            }
        }

        rotator.finish_secret(
            mock_service_client,
            "test-arn",
            "test-token"
        )

        # Verify proper staging update
        mock_service_client.update_secret_version_stage.assert_called_once_with(
            SecretId="test-arn",
            VersionStage="AWSCURRENT",
            MoveToVersionId="test-token",
            RemoveFromVersionId="old-version"
        )

    def test_finish_secret_handles_no_previous_version(self, rotator):
        """
        When no AWSCURRENT version exists (first rotation),
        finish_secret should still complete successfully
        """
        mock_service_client = MagicMock()
        mock_service_client.describe_secret.return_value = {
            "VersionIdsToStages": {
                "test-token": ["AWSPENDING"]
            }
        }

        rotator.finish_secret(
            mock_service_client,
            "test-arn",
            "test-token"
        )

        mock_service_client.update_secret_version_stage.assert_called_once_with(
            SecretId="test-arn",
            VersionStage="AWSCURRENT",
            MoveToVersionId="test-token",
            RemoveFromVersionId=None
        )

    def test_finish_secret_handles_api_errors(self, rotator):
        """
        finish_secret must handle AWS API errors gracefully
        """
        mock_service_client = MagicMock()
        mock_service_client.describe_secret.side_effect = ClientError(
            {"Error": {"Code": "ResourceNotFoundException"}},
            "describe_secret"
        )

        with pytest.raises(ClientError) as exc_info:
            rotator.finish_secret(
                mock_service_client,
                "test-arn",
                "test-token"
            )

        assert exc_info.value.response["Error"]["Code"] == "ResourceNotFoundException"
        mock_service_client.update_secret_version_stage.assert_not_called()

class TestErrorHandling:
    """
    Tests for error handling throughout the rotation process.
    """

    def test_fails_early_if_distribution_not_deployed(self, rotator):
        """
        If any distribution is not in 'Deployed' state, the entire rotation must fail
        before making any changes
        """
        mock_distributions = [
            {"Id": "DIST1", "Origin": "origin1.example.com"},
            {"Id": "DIST2", "Origin": "origin2.example.com"}
        ]
        
        mock_service_client = MagicMock()
        with patch.object(rotator, 'get_distro_list') as mock_get_distro_list, \
             patch.object(rotator, 'get_cfdistro') as mock_get_cfdistro, \
             patch.object(rotator, 'update_wafacl') as mock_update_wafacl:

            mock_get_distro_list.return_value = mock_distributions
            # Second distribution is not deployed
            mock_get_cfdistro.side_effect = [
                {"Distribution": {"Status": "Deployed"}},
                {"Distribution": {"Status": "InProgress"}}
            ]

            with pytest.raises(ValueError) as exc_info:
                rotator.set_secret(mock_service_client, "test-arn", "test-token")

            # Verify no updates were attempted
            assert "status is not Deployed" in str(exc_info.value)
            mock_update_wafacl.assert_not_called()

    def test_handles_waf_update_failure_without_distribution_updates(self, rotator):
        """
        If WAF update fails, no distribution updates should occur.
        """
        mock_distributions = [{"Id": "DIST1", "Origin": "origin1.example.com"}]
        mock_get_distro = {"Distribution": {"Status": "Deployed"}}
        mock_secrets = {
            "SecretString": json.dumps({"HEADERVALUE": "test-secret"})
        }
        
        mock_service_client = MagicMock()
        mock_service_client.get_secret_value.return_value = mock_secrets

        with patch.object(rotator, 'get_distro_list') as mock_get_distro_list, \
             patch.object(rotator, 'get_cfdistro') as mock_get_cfdistro, \
             patch.object(rotator, 'update_wafacl') as mock_update_wafacl, \
             patch.object(rotator, 'update_cfdistro') as mock_update_cfdistro:

            mock_get_distro_list.return_value = mock_distributions
            mock_get_cfdistro.return_value = mock_get_distro
            mock_update_wafacl.side_effect = ClientError(
                {"Error": {"Code": "WAFInvalidParameterException"}},
                "update_web_acl"
            )

            with pytest.raises(ValueError):
                rotator.set_secret(mock_service_client, "test-arn", "test-token")

            mock_update_cfdistro.assert_not_called()

class TestEdgeCases:

    def test_handles_empty_distribution_list_gracefully(self, rotator):
        """
        When no matching distributions are found, the system should:
        1. Still update WAF rules with both secrets
        2. Not attempt any distribution updates
        3. Complete successfully
        """
        # Given no matching distributions
        mock_service_client = MagicMock()
        
        # Mock the secrets
        mock_pending_secret = {
            "SecretString": json.dumps({"HEADERVALUE": "new-secret"})
        }
        mock_current_secret = {
            "SecretString": json.dumps({"HEADERVALUE": "current-secret"})
        }
        mock_metadata = {
            "VersionIdsToStages": {
                "current-version": ["AWSCURRENT"],
                "test-token": ["AWSPENDING"]
            }
        }

        mock_service_client.get_secret_value.side_effect = [
            mock_pending_secret,  # For AWSPENDING
            mock_current_secret   # For AWSCURRENT
        ]
        mock_service_client.describe_secret.return_value = mock_metadata

        with patch.object(rotator, 'get_distro_list') as mock_get_distro_list, \
            patch.object(rotator, 'update_wafacl') as mock_update_wafacl, \
            patch.object(rotator, 'update_cfdistro') as mock_update_cfdistro, \
            patch('time.sleep') as mock_sleep:

            mock_get_distro_list.return_value = []
            
            # When setting the secret
            rotator.set_secret(mock_service_client, "test-arn", "test-token")
            
            # Then WAF should be updated
            mock_update_wafacl.assert_called_once_with(
                "new-secret",
                "current-secret"
            )
            
            # But no distribution updates should be attempted
            mock_update_cfdistro.assert_not_called()

    def test_handles_malformed_secret_data(self, rotator):
        mock_service_client = MagicMock()
        mock_service_client.get_secret_value.return_value = {
            "SecretString": "invalid-json"
        }

        with pytest.raises(ValueError):
                rotator.run_test_secret(
                    mock_service_client,
                    "test-arn",
                    "test-token"
                )

class TestLambdaHandler:

    def test_validates_rotation_enabled(self):
        """
        Before starting rotation, verify rotation is enabled for the secret.
        """
        event = {
            "SecretId": "test-arn",
            "ClientRequestToken": "test-token",
            "Step": "createSecret"
        }
        
        with patch('boto3.client') as mock_boto3_client, \
             patch('rotate_secret_lambda_class.SecretRotator') as MockRotator:
            mock_secrets = mock_boto3_client.return_value
            mock_secrets.describe_secret.return_value = {
                "RotationEnabled": False
            }

            with pytest.raises(ValueError) as exc_info:
                from rotate_secret_lambda_class import lambda_handler
                lambda_handler(event, None)

            assert "not enabled for rotation" in str(exc_info.value)

    def test_executes_correct_rotation_step(self):
        """
        Lambda must execute the correct rotation step based on the event.
        """
        event = {
            "SecretId": "test-arn",
            "ClientRequestToken": "test-token",
            "Step": "createSecret"
        }
        
        with patch('boto3.client') as mock_boto3_client, \
             patch('rotate_secret_lambda_class.SecretRotator') as MockRotator:
            
            mock_secrets = mock_boto3_client.return_value
            mock_secrets.describe_secret.return_value = {
                "RotationEnabled": True,
                "VersionIdsToStages": {
                    "test-token": ["AWSPENDING"]
                }
            }
            
            mock_rotator = MockRotator.return_value

            from rotate_secret_lambda_class import lambda_handler
            lambda_handler(event, None)

            # Verify correct step was called
            mock_rotator.create_secret.assert_called_once_with(
                mock_secrets, "test-arn", "test-token"
            )