variables {
  application = "log-test-application"
  environment = "log-test-environment"
}

run "aws_iam_policy_unit_test" {
  command = plan

  assert {
    condition     = data.aws_iam_policy_document.log-policy.statement[0].resources == "test"
    error_message = "Invalid value for aws_iam_policy_document bucket_policy.statement.effect, should be Deny"
  }
}
