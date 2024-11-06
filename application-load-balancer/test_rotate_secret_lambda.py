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