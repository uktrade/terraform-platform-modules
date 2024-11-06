import pytest
from unittest.mock import patch, MagicMock

from rotate_secret_lambda_class import SecretRotator

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