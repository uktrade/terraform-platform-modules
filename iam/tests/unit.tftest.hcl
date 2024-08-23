variables {
  application = "iam-test-application"
  environment = "iam-test-environment"
  config = {
    "role_arn" = "test-role-arn"
    "bucket_actions" = ["TEST"]
  }
  resource_arn = "test-bucket-arn"
}


run "aws_iam_unit_test" {
  command = plan

  assert {
    condition     = aws_iam_role.external_service_access_role.name == "TEST-ExternalServiceAccessRole"
    error_message = "Should be: TEST-ExternalServiceAccessRole"
  }

  assert {
    condition     = aws_iam_role.external_service_access_role.assume_role_policy != null
    error_message = "Role should have an assume role policy"
  }

  assert {
    condition     = aws_iam_role_policy.permissions_s3_policy.name == "iam-test-application-iam-test-environment-permissions-s3-policy"
    error_message = "Should be: iam-test-application-iam-test-environment-permissions-s3-policy"
  }

  assert {
    condition     = aws_iam_role_policy.permissions_s3_policy.role == "TEST-ExternalServiceAccessRole"
    error_message = "Should be: TEST-ExternalServiceAccessRole"
  }

  assert {
    condition     = can(regex("test-bucket-arn", aws_iam_role_policy.permissions_s3_policy.policy))
    error_message = "Statement should contain resource arn: test-bucket-arn"
  }
}