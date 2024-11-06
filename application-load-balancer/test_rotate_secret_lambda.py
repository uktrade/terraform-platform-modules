import pytest
from unittest.mock import patch, MagicMock, call
from botocore.exceptions import ClientError
from rotate_secret_lambda_class import SecretRotator
import json

@pytest.fixture(autouse=True, scope="session")
def rotator_with_dummy_envs():
    return SecretRotator(
        waf_acl_name = "test-waf-id",
        waf_acl_id = "test-waf-acl",
        waf_rule_priority = "0",
        header_name = "x-origin-verify",
        application = "test-app",
        environment = "test",
        role_arn = "arn:aws:iam::123456789012:role/test-role",
        distro_list = "example.com,example2.com",
    )

def test_cloudfront_session_is_created_with_correct_role(rotator_with_dummy_envs):
    mock_credentials = {
        "Credentials": {
            "AccessKeyId": "test-access-key",
            "SecretAccessKey": "test-secret-key",
            "SessionToken": "test-session-token"
        }
    }

    with patch('boto3.client') as mock_boto3_client:
        mock_sts = mock_boto3_client.return_value
        mock_sts.assume_role.return_value = mock_credentials
        
        client = rotator_with_dummy_envs.get_cloudfront_session()
        
        mock_boto3_client.assert_any_call('sts')

        mock_sts.assume_role.assert_called_once_with(
            RoleArn="arn:aws:iam::123456789012:role/test-role",
            RoleSessionName='rotation_session'
        )
        
        mock_boto3_client.assert_any_call('cloudfront',
            aws_access_key_id="test-access-key",
            aws_secret_access_key="test-secret-key",
            aws_session_token="test-session-token"
        )

def test_get_distro_list_returns_matching_distributions(rotator_with_dummy_envs):
    mock_distributions = {
        "DistributionList": {
            "Items": [
                {
                    "Id": "DIST1",
                    "Origins": {"Items": [{"DomainName": "origin1.example.com"}]},
                    "Aliases": {"Items": ["example.com"]}
                },
                {
                    "Id": "DIST2",
                    "Origins": {"Items": [{"DomainName": "origin2.example.com"}]},
                    "Aliases": {"Items": ["example2.com"]}
                },
                {
                    "Id": "DIST3",
                    "Origins": {"Items": [{"DomainName": "origin3.example.com"}]},
                    "Aliases": {"Items": ["non-matching.com"]}
                }
            ]
        }
    }

    with patch.object(rotator_with_dummy_envs, 'get_cloudfront_session') as mock_session:
        mock_client = MagicMock()
        mock_paginator = MagicMock()
        mock_paginator.paginate.return_value = [mock_distributions]
        mock_client.get_paginator.return_value = mock_paginator
        mock_session.return_value = mock_client

        result = rotator_with_dummy_envs.get_distro_list()

        assert len(result) == 2
        assert result[0]["Id"] == "DIST1"
        assert result[1]["Id"] == "DIST2"
        mock_client.get_paginator.assert_called_once_with("list_distributions")

def test_get_wafacl_makes_correct_api_call(rotator_with_dummy_envs):
    with patch('boto3.client') as mock_boto3_client:
        mock_wafv2 = mock_boto3_client.return_value
        mock_wafv2.get_web_acl.return_value = {"WebACL": {"Name": "test-waf"}}

        result = rotator_with_dummy_envs.get_wafacl()

        mock_wafv2.get_web_acl.assert_called_once_with(
            Name="test-waf-id",
            Scope="REGIONAL",
            Id="test-waf-acl"
        )

def test_update_wafacl_preserves_existing_rules(rotator_with_dummy_envs):
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
         patch.object(rotator_with_dummy_envs, 'get_wafacl') as mock_get_wafacl:
        
        mock_get_wafacl.return_value = current_rules
        mock_wafv2 = mock_boto3_client.return_value

        rotator_with_dummy_envs.update_wafacl("new-secret", "old-secret")

        call_args = mock_wafv2.update_web_acl.call_args[1]
        assert len(call_args['Rules']) == 3
        assert call_args['LockToken'] == "test-lock-token"
        
        existing_rules = [r for r in call_args['Rules'] if r.get('Name') in ['ExistingRule1', 'ExistingRule2']]
        assert len(existing_rules) == 2

def test_update_cfdistro_handles_deployed_distribution(rotator_with_dummy_envs):
    mock_dist_status = {
        "Distribution": {"Status": "Deployed"}
    }
    mock_dist_config = {
        "DistributionConfig": {
            "Origins": {
                "Items": [{
                    "Id": "origin1",
                    "CustomHeaders": {
                        "Quantity": 1,
                        "Items": [{
                            "HeaderName": "x-origin-verify",
                            "HeaderValue": "old-value"
                        }]
                    }
                }]
            }
        },
        "ResponseMetadata": {
            "HTTPHeaders": {"etag": "test-etag"}
        }
    }

    with patch.object(rotator_with_dummy_envs, 'get_cloudfront_session') as mock_session, \
         patch.object(rotator_with_dummy_envs, 'get_cfdistro') as mock_get_cfdistro, \
         patch.object(rotator_with_dummy_envs, 'get_cfdistro_config') as mock_get_config:
        
        mock_client = MagicMock()
        mock_session.return_value = mock_client
        mock_get_cfdistro.return_value = mock_dist_status
        mock_get_config.return_value = mock_dist_config

        rotator_with_dummy_envs.update_cfdistro("DIST1", "new-header-value")

        mock_client.update_distribution.assert_called_once()
        call_args = mock_client.update_distribution.call_args[1]
        assert call_args['Id'] == "DIST1"
        assert call_args['IfMatch'] == "test-etag"

def test_create_secret_generates_new_secret_when_pending_not_exists(rotator_with_dummy_envs):
    """Test the happy path - AWSCURRENT exists but AWSPENDING doesn't"""
    mock_service_client = MagicMock()
    mock_service_client.exceptions.ResourceNotFoundException = ClientError
    
    # First call for AWSCURRENT succeeds, second call for AWSPENDING raises ResourceNotFound
    mock_service_client.get_secret_value.side_effect = [
        {"SecretString": '{"HEADERVALUE":"current-secret"}'}, # AWSCURRENT exists
        ClientError({"Error": {"Code": "ResourceNotFoundException"}}, "operation") # AWSPENDING doesn't exist
    ]
    mock_service_client.get_random_password.return_value = {"RandomPassword": "generated-password"}

    rotator_with_dummy_envs.create_secret(mock_service_client, "test-arn", "test-token")

    # Verify the correct sequence of API calls
    mock_service_client.get_secret_value.assert_has_calls([
        call(SecretId="test-arn", VersionStage="AWSCURRENT"),
        call(SecretId="test-arn", VersionId="test-token", VersionStage="AWSPENDING")
    ])
    
    # Verify random password was requested
    mock_service_client.get_random_password.assert_called_once_with(
        ExcludePunctuation=True
    )

    # Verify the new secret was stored correctly
    mock_service_client.put_secret_value.assert_called_once_with(
        SecretId="test-arn",
        ClientRequestToken="test-token",
        SecretString='{"HEADERVALUE":"generated-password"}',
        VersionStages=['AWSPENDING']
    )

def test_create_secret_when_pending_already_exists(rotator_with_dummy_envs):
    """Test when both AWSCURRENT and AWSPENDING exist"""
    mock_service_client = MagicMock()
    mock_service_client.exceptions.ResourceNotFoundException = ClientError
    
    # Both AWSCURRENT and AWSPENDING exist
    mock_service_client.get_secret_value.side_effect = [
        {"SecretString": '{"HEADERVALUE":"current-secret"}'}, # AWSCURRENT response
        {"SecretString": '{"HEADERVALUE":"pending-secret"}'} # AWSPENDING response
    ]

    rotator_with_dummy_envs.create_secret(mock_service_client, "test-arn", "test-token")

    # Verify we checked both versions
    mock_service_client.get_secret_value.assert_has_calls([
        call(SecretId="test-arn", VersionStage="AWSCURRENT"),
        call(SecretId="test-arn", VersionId="test-token", VersionStage="AWSPENDING")
    ])
    
    # Verify we didn't try to create a new secret
    mock_service_client.get_random_password.assert_not_called()
    mock_service_client.put_secret_value.assert_not_called()

def test_create_secret_when_current_does_not_exist(rotator_with_dummy_envs):
    """Test error handling when AWSCURRENT doesn't exist"""
    mock_service_client = MagicMock()
    mock_service_client.exceptions.ResourceNotFoundException = ClientError
    
    # AWSCURRENT doesn't exist
    mock_service_client.get_secret_value.side_effect = ClientError(
        {"Error": {"Code": "ResourceNotFoundException"}},
        "get_secret_value"
    )

    # Should raise the exception since AWSCURRENT must exist
    with pytest.raises(ClientError) as exc_info:
        rotator_with_dummy_envs.create_secret(mock_service_client, "test-arn", "test-token")

    # Verify we only tried to get AWSCURRENT
    mock_service_client.get_secret_value.assert_called_once_with(
        SecretId="test-arn",
        VersionStage="AWSCURRENT"
    )
    
    # Verify we didn't proceed with other operations
    mock_service_client.get_random_password.assert_not_called()
    mock_service_client.put_secret_value.assert_not_called()

def test_create_secret_handles_random_password_error(rotator_with_dummy_envs):
    """Test error handling when random password generation fails"""
    mock_service_client = MagicMock()
    mock_service_client.exceptions.ResourceNotFoundException = ClientError
    
    # AWSCURRENT exists, AWSPENDING doesn't
    mock_service_client.get_secret_value.side_effect = [
        {"SecretString": '{"HEADERVALUE":"current-secret"}'}, # AWSCURRENT exists
        ClientError({"Error": {"Code": "ResourceNotFoundException"}}, "operation") # AWSPENDING doesn't exist
    ]
    
    # Random password generation fails
    mock_service_client.get_random_password.side_effect = ClientError(
        {"Error": {"Code": "InternalServiceError"}},
        "get_random_password"
    )

    # Should raise the error
    with pytest.raises(ClientError) as exc_info:
        rotator_with_dummy_envs.create_secret(mock_service_client, "test-arn", "test-token")

    assert exc_info.value.response["Error"]["Code"] == "InternalServiceError"
    mock_service_client.put_secret_value.assert_not_called()

def test_create_secret_handles_put_secret_error(rotator_with_dummy_envs):
    """Test error handling when putting the new secret fails"""
    mock_service_client = MagicMock()
    mock_service_client.exceptions.ResourceNotFoundException = ClientError
    
    # Setup normal responses for get_secret_value
    mock_service_client.get_secret_value.side_effect = [
        {"SecretString": '{"HEADERVALUE":"current-secret"}'}, # AWSCURRENT exists
        ClientError({"Error": {"Code": "ResourceNotFoundException"}}, "operation") # AWSPENDING doesn't exist
    ]
    mock_service_client.get_random_password.return_value = {"RandomPassword": "generated-password"}
    
    # Make put_secret_value fail
    mock_service_client.put_secret_value.side_effect = ClientError(
        {"Error": {"Code": "InternalServiceError"}},
        "put_secret_value"
    )

    # Should raise the error
    with pytest.raises(ClientError) as exc_info:
        rotator_with_dummy_envs.create_secret(mock_service_client, "test-arn", "test-token")

    assert exc_info.value.response["Error"]["Code"] == "InternalServiceError"
    
    # Verify we tried to put the secret
    mock_service_client.put_secret_value.assert_called_once()

def test_set_secret_happy_path(rotator_with_dummy_envs):
    """Test the happy path for setting a secret"""
    # Setup mock for get_distro_list
    mock_distributions = [
        {"Id": "DIST1", "Origin": "origin1.example.com"},
        {"Id": "DIST2", "Origin": "origin2.example.com"}
    ]
    
    # Mock all the service responses
    mock_service_client = MagicMock()
    mock_get_distro = {
        "Distribution": {"Status": "Deployed"}
    }
    mock_metadata = {
        "VersionIdsToStages": {
            "current-version": ["AWSCURRENT"],
            "test-token": ["AWSPENDING"]
        }
    }
    mock_pending_secret = {
        "SecretString": json.dumps({"HEADERVALUE": "new-secret"})
    }
    mock_current_secret = {
        "SecretString": json.dumps({"HEADERVALUE": "current-secret"})
    }

    # Setup all our patches
    with patch.object(rotator_with_dummy_envs, 'get_distro_list') as mock_get_distro_list, \
         patch.object(rotator_with_dummy_envs, 'get_cfdistro') as mock_get_cfdistro, \
         patch.object(rotator_with_dummy_envs, 'update_wafacl') as mock_update_wafacl, \
         patch.object(rotator_with_dummy_envs, 'update_cfdistro') as mock_update_cfdistro, \
         patch('time.sleep') as mock_sleep:
        
        # Configure our mocks
        mock_get_distro_list.return_value = mock_distributions
        mock_get_cfdistro.return_value = mock_get_distro
        mock_service_client.describe_secret.return_value = mock_metadata
        mock_service_client.get_secret_value.side_effect = [
            mock_pending_secret,  # First call for pending
            mock_current_secret   # Second call for current
        ]

        # Call the method
        rotator_with_dummy_envs.set_secret(
            mock_service_client, 
            "test-arn", 
            "test-token"
        )

        # Verify the sequence of operations
        mock_get_distro_list.assert_called_once()
        mock_get_cfdistro.assert_has_calls([
            call("DIST1"),
            call("DIST2")
        ])
        
        # Verify WAF update
        mock_update_wafacl.assert_called_once_with(
            "new-secret",
            "current-secret"
        )
        
        # Verify the sleep was called
        mock_sleep.assert_called_once_with(75)
        
        # Verify distribution updates
        mock_update_cfdistro.assert_has_calls([
            call("DIST1", "new-secret"),
            call("DIST2", "new-secret")
        ])

def test_set_secret_distribution_not_deployed(rotator_with_dummy_envs):
    """Test handling of non-deployed distribution"""
    mock_distributions = [
        {"Id": "DIST1", "Origin": "origin1.example.com"}
    ]
    
    mock_get_distro = {
        "Distribution": {"Status": "InProgress"}
    }

    with patch.object(rotator_with_dummy_envs, 'get_distro_list') as mock_get_distro_list, \
         patch.object(rotator_with_dummy_envs, 'get_cfdistro') as mock_get_cfdistro:
        
        mock_get_distro_list.return_value = mock_distributions
        mock_get_cfdistro.return_value = mock_get_distro

        with pytest.raises(ValueError) as exc_info:
            rotator_with_dummy_envs.set_secret(MagicMock(), "test-arn", "test-token")

        assert "Distribution Id, DIST1 status is not Deployed" in str(exc_info.value)

def test_set_secret_handles_no_distributions(rotator_with_dummy_envs):
    """Test handling when no distributions are found"""
    # Create mock service client
    mock_service_client = MagicMock()
    
    # Set up proper mock returns for secret operations
    mock_service_client.get_secret_value.return_value = {
        'SecretString': json.dumps({
            'HEADERVALUE': 'test-header-value'
        })
    }
    mock_service_client.describe_secret.return_value = {
        "VersionIdsToStages": {
            "version1": ["AWSCURRENT"]
        }
    }

    # Mock WAF operations
    with patch('boto3.client') as mock_boto3_client:
        mock_waf_client = MagicMock()
        mock_boto3_client.return_value = mock_waf_client

        with patch.object(rotator_with_dummy_envs, 'get_distro_list') as mock_get_distro_list:
            with patch.object(rotator_with_dummy_envs, 'get_cfdistro') as mock_get_cfdistro, \
                 patch('time.sleep') as mock_sleep:
                # Set up empty distributions list
                mock_get_distro_list.return_value = []
                
                # Mock distribution status (although it won't be called in this test)
                mock_get_cfdistro.return_value = {
                    'Distribution': {
                        'Status': 'Deployed'
                    }
                }
                
                rotator_with_dummy_envs.set_secret(mock_service_client, "test-arn", "test-token")

                # Verify the sleep was called
                mock_sleep.assert_called_once_with(75)
                # Verify get_cfdistro was never called since there were no distributions
                mock_get_cfdistro.assert_not_called()

def test_set_secret_handles_waf_update_failure(rotator_with_dummy_envs):
    """Test handling of WAF update failure"""
    mock_distributions = [
        {"Id": "DIST1", "Origin": "origin1.example.com"}
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
            "current-version": ["AWSCURRENT"]
        }
    }

    with patch.object(rotator_with_dummy_envs, 'get_distro_list') as mock_get_distro_list, \
         patch.object(rotator_with_dummy_envs, 'get_cfdistro') as mock_get_cfdistro, \
         patch.object(rotator_with_dummy_envs, 'update_wafacl') as mock_update_wafacl:
        
        mock_get_distro_list.return_value = mock_distributions
        mock_get_cfdistro.return_value = mock_get_distro
        mock_update_wafacl.side_effect = ClientError(
            {"Error": {"Code": "WAFInvalidParameterException"}},
            "update_web_acl"
        )

        mock_service_client = MagicMock()
        mock_service_client.describe_secret.return_value = mock_metadata
        mock_service_client.get_secret_value.side_effect = [
            mock_pending_secret,
            mock_current_secret
        ]

        with pytest.raises(ValueError) as exc_info:
            rotator_with_dummy_envs.set_secret(
                mock_service_client, 
                "test-arn", 
                "test-token"
            )

        assert "Failed to update resources" in str(exc_info.value)

def test_set_secret_handles_distro_update_failure(rotator_with_dummy_envs):
    """Test handling of distribution update failure"""
    mock_distributions = [
        {"Id": "DIST1", "Origin": "origin1.example.com"}
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
            "current-version": ["AWSCURRENT"]
        }
    }

    with patch.object(rotator_with_dummy_envs, 'get_distro_list') as mock_get_distro_list, \
         patch.object(rotator_with_dummy_envs, 'get_cfdistro') as mock_get_cfdistro, \
         patch.object(rotator_with_dummy_envs, 'update_wafacl') as mock_update_wafacl, \
         patch.object(rotator_with_dummy_envs, 'update_cfdistro') as mock_update_cfdistro, \
         patch('time.sleep'):
        
        mock_get_distro_list.return_value = mock_distributions
        mock_get_cfdistro.return_value = mock_get_distro
        mock_update_cfdistro.side_effect = ClientError(
            {"Error": {"Code": "InvalidParameter"}},
            "update_distribution"
        )

        mock_service_client = MagicMock()
        mock_service_client.describe_secret.return_value = mock_metadata
        mock_service_client.get_secret_value.side_effect = [
            mock_pending_secret,
            mock_current_secret
        ]

        with pytest.raises(ValueError) as exc_info:
            rotator_with_dummy_envs.set_secret(
                mock_service_client, 
                "test-arn", 
                "test-token"
            )

        assert "Failed to update resources" in str(exc_info.value)

def test_set_secret_handles_secret_retrieval_failure(rotator_with_dummy_envs):
    """Test handling of secret retrieval failure"""
    mock_distributions = [
        {"Id": "DIST1", "Origin": "origin1.example.com"}
    ]
    
    mock_get_distro = {
        "Distribution": {"Status": "Deployed"}
    }

    with patch.object(rotator_with_dummy_envs, 'get_distro_list') as mock_get_distro_list, \
         patch.object(rotator_with_dummy_envs, 'get_cfdistro') as mock_get_cfdistro:
        
        mock_get_distro_list.return_value = mock_distributions
        mock_get_cfdistro.return_value = mock_get_distro

        mock_service_client = MagicMock()
        mock_service_client.get_secret_value.side_effect = ClientError(
            {"Error": {"Code": "ResourceNotFoundException"}},
            "get_secret_value"
        )

        with pytest.raises(ClientError) as exc_info:
            rotator_with_dummy_envs.set_secret(
                mock_service_client, 
                "test-arn", 
                "test-token"
            )

        assert exc_info.value.response["Error"]["Code"] == "ResourceNotFoundException"

def test_run_test_secret_happy_path(rotator_with_dummy_envs):
    """Test successful testing of both pending and current secrets"""
    # Setup our test data
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

    # Setup our service client mock
    mock_service_client = MagicMock()
    mock_service_client.get_secret_value.side_effect = [
        mock_pending_secret,  # First call for AWSPENDING
        mock_current_secret   # Second call for AWSCURRENT
    ]
    mock_service_client.describe_secret.return_value = mock_metadata

    with patch.object(rotator_with_dummy_envs, 'get_distro_list') as mock_get_distro_list, \
         patch.object(rotator_with_dummy_envs, 'run_test_origin') as mock_run_test_origin:
        
        mock_get_distro_list.return_value = mock_distributions
        mock_run_test_origin.return_value = True  # All origin tests pass

        # Run the test
        rotator_with_dummy_envs.run_test_secret(
            mock_service_client,
            "test-arn",
            "test-token"
        )

        # Verify we got both secrets
        mock_service_client.get_secret_value.assert_has_calls([
            call(SecretId="test-arn", VersionId="test-token", VersionStage="AWSPENDING"),
            call(SecretId="test-arn", VersionId="current-version", VersionStage="AWSCURRENT")
        ])

        # Verify we tested both origins with both secrets
        expected_test_calls = [
            call("http://origin1.example.com", "new-secret"),
            call("http://origin1.example.com", "current-secret"),
            call("http://origin2.example.com", "new-secret"),
            call("http://origin2.example.com", "current-secret")
        ]
        mock_run_test_origin.assert_has_calls(expected_test_calls)

def test_run_test_secret_fails_on_origin_test(rotator_with_dummy_envs):
    """Test handling of failed origin test"""
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
        {"Id": "DIST1", "Origin": "origin1.example.com"}
    ]

    mock_service_client = MagicMock()
    mock_service_client.get_secret_value.side_effect = [
        mock_pending_secret,
        mock_current_secret
    ]
    mock_service_client.describe_secret.return_value = mock_metadata

    with patch.object(rotator_with_dummy_envs, 'get_distro_list') as mock_get_distro_list, \
         patch.object(rotator_with_dummy_envs, 'run_test_origin') as mock_run_test_origin:
        
        mock_get_distro_list.return_value = mock_distributions
        mock_run_test_origin.return_value = False  # Origin test fails

        with pytest.raises(ValueError) as exc_info:
            rotator_with_dummy_envs.run_test_secret(
                mock_service_client,
                "test-arn",
                "test-token"
            )

        assert "Tests failed for URL" in str(exc_info.value)
        mock_run_test_origin.assert_called_once()  # Should fail on first test

def test_run_test_secret_handles_pending_secret_not_found(rotator_with_dummy_envs):
    """Test handling of missing pending secret"""
    mock_service_client = MagicMock()
    mock_service_client.get_secret_value.side_effect = ClientError(
        {"Error": {"Code": "ResourceNotFoundException"}},
        "get_secret_value"
    )

    with pytest.raises(ClientError) as exc_info:
        rotator_with_dummy_envs.run_test_secret(
            mock_service_client,
            "test-arn",
            "test-token"
        )

    assert exc_info.value.response["Error"]["Code"] == "ResourceNotFoundException"
    # Should fail on first get_secret_value call
    assert mock_service_client.get_secret_value.call_count == 1

def test_run_test_secret_handles_current_secret_not_found(rotator_with_dummy_envs):
    """Test handling of missing current secret"""
    mock_pending_secret = {
        "SecretString": json.dumps({"HEADERVALUE": "new-secret"})
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
        mock_pending_secret,  # AWSPENDING succeeds
        ClientError({"Error": {"Code": "ResourceNotFoundException"}}, "get_secret_value")  # AWSCURRENT fails
    ]

    with pytest.raises(ClientError) as exc_info:
        rotator_with_dummy_envs.run_test_secret(
            mock_service_client,
            "test-arn",
            "test-token"
        )

    assert exc_info.value.response["Error"]["Code"] == "ResourceNotFoundException"
    assert mock_service_client.get_secret_value.call_count == 2

def test_run_test_secret_handles_invalid_json(rotator_with_dummy_envs):
    """Test handling of invalid JSON in secret values"""
    mock_pending_secret = {
        "SecretString": "invalid-json"  # Not valid JSON
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
    mock_service_client.get_secret_value.side_effect = [
        mock_pending_secret,
        mock_current_secret
    ]
    mock_service_client.describe_secret.return_value = mock_metadata

    with pytest.raises(json.JSONDecodeError):
        rotator_with_dummy_envs.run_test_secret(
            mock_service_client,
            "test-arn",
            "test-token"
        )

def test_run_test_secret_handles_missing_header_value(rotator_with_dummy_envs):
    """Test handling of missing HEADERVALUE in secret"""
    mock_pending_secret = {
        "SecretString": json.dumps({"WRONGKEY": "new-secret"})  # Missing HEADERVALUE
    }
    mock_metadata = {
        "VersionIdsToStages": {
            "current-version": ["AWSCURRENT"],
            "test-token": ["AWSPENDING"]
        }
    }

    mock_service_client = MagicMock()
    mock_service_client.get_secret_value.return_value = mock_pending_secret
    mock_service_client.describe_secret.return_value = mock_metadata

    with pytest.raises(KeyError):
        rotator_with_dummy_envs.run_test_secret(
            mock_service_client,
            "test-arn",
            "test-token"
        )

def test_run_test_secret_handles_no_distributions(rotator_with_dummy_envs):
    """Test handling when no distributions are found"""
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
    mock_service_client.get_secret_value.side_effect = [
        mock_pending_secret,
        mock_current_secret
    ]
    mock_service_client.describe_secret.return_value = mock_metadata

    with patch.object(rotator_with_dummy_envs, 'get_distro_list') as mock_get_distro_list, \
         patch.object(rotator_with_dummy_envs, 'run_test_origin') as mock_run_test_origin:
        
        mock_get_distro_list.return_value = []  # No distributions

        # Should complete without error
        rotator_with_dummy_envs.run_test_secret(
            mock_service_client,
            "test-arn",
            "test-token"
        )

        # Verify we got the secrets but never tested origins
        assert mock_service_client.get_secret_value.call_count == 2
        mock_run_test_origin.assert_not_called()

def test_run_test_secret_handles_origin_test_error(rotator_with_dummy_envs):
    """Test handling of errors during origin testing"""
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
        {"Id": "DIST1", "Origin": "origin1.example.com"}
    ]

    mock_service_client = MagicMock()
    mock_service_client.get_secret_value.side_effect = [
        mock_pending_secret,
        mock_current_secret
    ]
    mock_service_client.describe_secret.return_value = mock_metadata

    with patch.object(rotator_with_dummy_envs, 'get_distro_list') as mock_get_distro_list, \
         patch.object(rotator_with_dummy_envs, 'run_test_origin') as mock_run_test_origin:
        
        mock_get_distro_list.return_value = mock_distributions
        mock_run_test_origin.side_effect = Exception("Network error")

        with pytest.raises(Exception) as exc_info:
            rotator_with_dummy_envs.run_test_secret(
                mock_service_client,
                "test-arn",
                "test-token"
            )

        assert "Network error" in str(exc_info.value)

def test_finish_secret_happy_path(rotator_with_dummy_envs):
    """Test successful transition of a secret from PENDING to CURRENT"""
    mock_service_client = MagicMock()
    mock_service_client.describe_secret.return_value = {
        "VersionIdsToStages": {
            "current-version": ["AWSCURRENT"],
            "test-token": ["AWSPENDING"]
        }
    }

    rotator_with_dummy_envs.finish_secret(
        mock_service_client,
        "test-arn",
        "test-token"
    )

    # Verify describe_secret was called first
    mock_service_client.describe_secret.assert_called_once_with(
        SecretId="test-arn"
    )

    # Verify update_secret_version_stage was called with correct params
    mock_service_client.update_secret_version_stage.assert_called_once_with(
        SecretId="test-arn",
        VersionStage="AWSCURRENT",
        MoveToVersionId="test-token",
        RemoveFromVersionId="current-version"
    )

def test_finish_secret_when_already_current(rotator_with_dummy_envs):
    """Test when the secret version is already marked as CURRENT"""
    mock_service_client = MagicMock()
    mock_service_client.describe_secret.return_value = {
        "VersionIdsToStages": {
            "test-token": ["AWSCURRENT", "AWSPENDING"]
        }
    }

    rotator_with_dummy_envs.finish_secret(
        mock_service_client,
        "test-arn",
        "test-token"
    )

    # Verify we only called describe_secret and didn't try to update
    mock_service_client.describe_secret.assert_called_once_with(
        SecretId="test-arn"
    )
    mock_service_client.update_secret_version_stage.assert_not_called()

def test_finish_secret_no_current_version(rotator_with_dummy_envs):
    """Test handling when no CURRENT version exists"""
    mock_service_client = MagicMock()
    mock_service_client.describe_secret.return_value = {
        "VersionIdsToStages": {
            "test-token": ["AWSPENDING"]
        }
    }

    rotator_with_dummy_envs.finish_secret(
        mock_service_client,
        "test-arn",
        "test-token"
    )

    # Verify we update with no RemoveFromVersionId
    mock_service_client.update_secret_version_stage.assert_called_once_with(
        SecretId="test-arn",
        VersionStage="AWSCURRENT",
        MoveToVersionId="test-token",
        RemoveFromVersionId=None
    )

def test_finish_secret_handles_describe_error(rotator_with_dummy_envs):
    """Test handling of errors during describe_secret"""
    mock_service_client = MagicMock()
    mock_service_client.describe_secret.side_effect = ClientError(
        {"Error": {"Code": "ResourceNotFoundException"}},
        "describe_secret"
    )

    with pytest.raises(ClientError) as exc_info:
        rotator_with_dummy_envs.finish_secret(
            mock_service_client,
            "test-arn",
            "test-token"
        )

    assert exc_info.value.response["Error"]["Code"] == "ResourceNotFoundException"
    mock_service_client.update_secret_version_stage.assert_not_called()

def test_finish_secret_handles_update_error(rotator_with_dummy_envs):
    """Test handling of errors during update_secret_version_stage"""
    mock_service_client = MagicMock()
    mock_service_client.describe_secret.return_value = {
        "VersionIdsToStages": {
            "current-version": ["AWSCURRENT"],
            "test-token": ["AWSPENDING"]
        }
    }
    mock_service_client.update_secret_version_stage.side_effect = ClientError(
        {"Error": {"Code": "ResourceNotFoundException"}},
        "update_secret_version_stage"
    )

    with pytest.raises(ClientError) as exc_info:
        rotator_with_dummy_envs.finish_secret(
            mock_service_client,
            "test-arn",
            "test-token"
        )

    assert exc_info.value.response["Error"]["Code"] == "ResourceNotFoundException"

def test_finish_secret_with_multiple_version_stages(rotator_with_dummy_envs):
    """Test handling of multiple version stages"""
    mock_service_client = MagicMock()
    mock_service_client.describe_secret.return_value = {
        "VersionIdsToStages": {
            "current-version": ["AWSCURRENT", "AWSPREVIOUS"],
            "test-token": ["AWSPENDING"],
            "old-version": ["AWSPREVIOUS"]
        }
    }

    rotator_with_dummy_envs.finish_secret(
        mock_service_client,
        "test-arn",
        "test-token"
    )

    # Verify we correctly identified the current version despite multiple stages
    mock_service_client.update_secret_version_stage.assert_called_once_with(
        SecretId="test-arn",
        VersionStage="AWSCURRENT",
        MoveToVersionId="test-token",
        RemoveFromVersionId="current-version"
    )

def test_finish_secret_with_empty_version_stages(rotator_with_dummy_envs):
    """Test handling of empty version stages"""
    mock_service_client = MagicMock()
    mock_service_client.describe_secret.return_value = {
        "VersionIdsToStages": {}
    }

    rotator_with_dummy_envs.finish_secret(
        mock_service_client,
        "test-arn",
        "test-token"
    )

    # Verify we handle empty version stages gracefully
    mock_service_client.update_secret_version_stage.assert_called_once_with(
        SecretId="test-arn",
        VersionStage="AWSCURRENT",
        MoveToVersionId="test-token",
        RemoveFromVersionId=None
    )

def test_finish_secret_version_not_found(rotator_with_dummy_envs):
    """Test when the specified version is not found in stages"""
    mock_service_client = MagicMock()
    mock_service_client.describe_secret.return_value = {
        "VersionIdsToStages": {
            "current-version": ["AWSCURRENT"],
            "other-version": ["AWSPENDING"]
        }
    }

    # The method should still work as it only cares about finding AWSCURRENT
    rotator_with_dummy_envs.finish_secret(
        mock_service_client,
        "test-arn",
        "test-token"
    )

    mock_service_client.update_secret_version_stage.assert_called_once_with(
        SecretId="test-arn",
        VersionStage="AWSCURRENT",
        MoveToVersionId="test-token",
        RemoveFromVersionId="current-version"
    )