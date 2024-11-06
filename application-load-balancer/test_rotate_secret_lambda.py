# import pytest
# import os
# from unittest.mock import patch
# os.environ['WAFACLID'] = 'test-waf-id'
# os.environ['WAFACLNAME'] = 'test-waf-name'
# os.environ['WAFRULEPRI'] = '0'
# os.environ['DISTROIDLIST'] = 'domain1.com,domain2.com'
# os.environ['HEADERNAME'] = 'x-origin-verify'
# os.environ['APPLICATION'] = 'test-app'
# os.environ['ENVIRONMENT'] = 'test-env'
# os.environ['ROLEARN'] = 'arn:aws:iam::123456789012:role/test-role'

# from rotate_secret_lambda import lambda_handler, get_cloudfront_session

# def test_env_is_setup():
#     assert os.environ.get('WAFACLNAME') == 'test-waf-name'

# def test_cloudfront_session_has_correct_credentials():
#     mock_credentials = {
#         "Credentials": {
#             "AccessKeyId": "test-access-key",
#             "SecretAccessKey": "test-secret-key",
#             "SessionToken": "test-session-token"
#         }
#     }

#     with patch('boto3.client') as mock_boto3_client:
#         mock_sts = mock_boto3_client.return_value
#         mock_sts.assume_role.return_value = mock_credentials

#         client = get_cloudfront_session()

#         mock_boto3_client.assert_any_call('sts')

        



 