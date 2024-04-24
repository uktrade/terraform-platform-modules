variables {
  application = "log-test-application"
  environment = "log-test-environment"
}

run "log_resource_policy_unit_test" {
  command = plan

  assert {
    condition     = [for el in data.aws_iam_policy_document.log-resource-policy.statement[0].condition : true if el.variable == "aws:SourceArn"][0] == true
    error_message = "Should be: aws:SourceArn"
  }

  assert {
    condition     = [for el in data.aws_iam_policy_document.log-resource-policy.statement[0].condition : true if el.variable == "aws:SourceAccount"][0] == true
    error_message = "Should be: aws:SourceAccount"
  }

  assert {
    condition     = jsondecode(data.aws_iam_policy_document.log-resource-policy.json).Statement[0].Principal.Service == "delivery.logs.amazonaws.com"
    error_message = "Should be: delivery.logs.amazonaws.com"
  }

  assert {
    condition     = strcontains(jsondecode(data.aws_iam_policy_document.log-resource-policy.json).Statement[0].Resource, "log-group:/copilot/log-test-application-log-test-environment-*:log-stream:*")
    error_message = "Invalid value for aws_iam_policy_document log_resource_policy statement resource should contain log-group:/copilot/log-test-application-log-test-environment-*:log-stream:*"
  }

  assert {
    condition     = [for el in data.aws_iam_policy_document.log-resource-policy.statement[1].condition : true if el.variable == "aws:SourceArn"][0] == true
    error_message = "Should be: aws:SourceArn"
  }

  assert {
    condition     = [for el in data.aws_iam_policy_document.log-resource-policy.statement[1].condition : true if el.variable == "aws:SourceAccount"][0] == true
    error_message = "Should be: aws:SourceAccount"
  }

  assert {
    condition     = jsondecode(data.aws_iam_policy_document.log-resource-policy.json).Statement[1].Principal.Service == "delivery.logs.amazonaws.com"
    error_message = "Should be: delivery.logs.amazonaws.com"
  }

  assert {
    condition     = strcontains(jsondecode(data.aws_iam_policy_document.log-resource-policy.json).Statement[1].Resource, "log-group:/aws/elasticache/log-test-application/log-test-environment/*")
    error_message = "Invalid value for aws_iam_policy_document log_resource_policy statement resource should contain log-group:/aws/elasticache/log-test-application/log-test-environment/*"
  }

  assert {
    condition     = [for el in data.aws_iam_policy_document.log-resource-policy.statement[2].condition : true if el.variable == "aws:SourceAccount"][0] == true
    error_message = "Should be: aws:SourceAccount"
  }

  assert {
    condition     = jsondecode(data.aws_iam_policy_document.log-resource-policy.json).Statement[2].Principal.Service == "es.amazonaws.com"
    error_message = "Should be: es.amazonaws.com"
  }

  assert {
    condition     = strcontains(jsondecode(data.aws_iam_policy_document.log-resource-policy.json).Statement[2].Resource, "log-group:/aws/opensearch/log-test-application/log-test-environment/*")
    error_message = "Invalid value for aws_iam_policy_document log_resource_policy statement resource should contain log-group:/aws/opensearch/log-test-application/log-test-environment/*"
  }
}
