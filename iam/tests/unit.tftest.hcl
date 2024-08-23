variables {
  application = "iam-test-application"
  environment = "iam-test-environment"
  config = {
    "role_arn" = "test-role-arn"
    "actions"  = ["TEST"]
  }
  resource_arn  = "test-bucket-arn"
  resource_name = "test-bucket-name"
}


run "aws_iam_unit_test" {
  command = plan

  assert {
    condition     = aws_iam_role.external_service_access_role.name == "test-bucket-name-ExternalAccess"
    error_message = "Should be: test-bucket-name-ExternalAccess"
  }

  assert {
    condition     = aws_iam_role.external_service_access_role.assume_role_policy != null
    error_message = "Role should have an assume role policy"
  }

  assert {
    condition     = aws_iam_role_policy.allow_actions.name == "iam-test-application-iam-test-environment-allow-actions"
    error_message = "Should be: iam-test-application-iam-test-environment-allow-actions"
  }

  assert {
    condition     = aws_iam_role_policy.allow_actions.role == "test-bucket-name-ExternalAccess"
    error_message = "Should be: test-bucket-name-ExternalAccess"
  }

  assert {
    condition     = can(regex("test-bucket-arn", aws_iam_role_policy.allow_actions.policy))
    error_message = "Statement should contain resource arn: test-bucket-arn"
  }
}