variables {
  application = "log-test-application"
  environment = "log-test-environment"
}

run "aws_iam_policy_unit_test" {
  command = plan

  assert {
    condition     = [for el in data.aws_iam_policy_document.log-policy.statement[0].condition : true if el.variable == "aws:SourceAccount"][0] == true
    error_message = "Invalid value log policy resources, should be "
  }

  assert {
    condition     = [for el in data.aws_iam_policy_document.log-policy.statement[0].resources : true if el == "arn:aws:logs:eu-west-2:812359060647:log-group:/copilot/test-application-test-environment-*:log-stream:*"][0] == true
    error_message = "Invalid value log policy resources, should be "
  }
}
