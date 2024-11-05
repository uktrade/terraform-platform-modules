import pytest
import boto3
import os
from unittest.mock import Mock, patch

# Define a fixture to set environment variables before tests
@pytest.fixture(autouse=True, scope='session')
def set_env_vars():
    # Backup original environment variables
    original_env = dict(os.environ)

    # Set up test environment variables
    os.environ["WAFACLNAME"] = "test-waf-id"
    os.environ["WAFACLID"] = "test-waf-acl"
    os.environ["WAFRULEPRI"] = "0"
    os.environ["HEADERNAME"] = "x-origin-verify"
    os.environ["APPLICATION"] = "test-app"
    os.environ["ENVIRONMENT"] = "test"
    os.environ["ROLEARN"] = "arn:aws:iam::123456789012:role/test-role"
    os.environ["DISTROIDLIST"] = "test1.example.com,test2.example.com"

    # Import the module after setting the environment variables
    from rotate_secret_lambda import (
        get_cloudfront_session,
        get_distro_list,
        get_wafacl,
        update_wafacl,
        get_cfdistro,
        update_cfdistro,
        run_test_origin,
        create_secret,
        set_secret,
        run_test_secret,
        finish_secret,
        lambda_handler,
    )

    # Yield the imported functions for use in tests
    yield {
        'get_cloudfront_session': get_cloudfront_session,
        'get_distro_list': get_distro_list,
        'get_wafacl': get_wafacl,
        'update_wafacl': update_wafacl,
        'get_cfdistro': get_cfdistro,
        'update_cfdistro': update_cfdistro,
        'run_test_origin': run_test_origin,
        'create_secret': create_secret,
        'set_secret': set_secret,
        'run_test_secret': run_test_secret,
        'finish_secret': finish_secret,
        'lambda_handler': lambda_handler,
    }

    # Restore original environment variables after tests
    os.environ = original_env

@pytest.mark.parametrize("sts_response, expected_success", [
    ({
        "Credentials": {
            "AccessKeyId": "test-key",
            "SecretAccessKey": "test-secret",
            "SessionToken": "test-token"
        }
    }, True),
    (None, False)
])
def test_get_cloudfront_session(set_env_vars, sts_response, expected_success):
    # Access the imported function from the fixture
    get_cloudfront_session = set_env_vars['get_cloudfront_session']

    with patch('boto3.client') as mock_boto:
        mock_sts = Mock()
        mock_sts.assume_role.return_value = sts_response
        mock_boto.return_value = mock_sts

        if expected_success:
            session = get_cloudfront_session()
            assert session is not None
        else:
            with pytest.raises(Exception):
                get_cloudfront_session()
