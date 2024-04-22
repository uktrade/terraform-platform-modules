variables {
  application = "log-test-application"
  environment = "log-test-environment"
}

run "log_policy_document_unit_test" {
  command = plan

  assert {
    condition     = jsondecode(data.aws_iam_policy_document.log-policy.json).Statement[0].Condition["ArnLike"]["aws:SourceArn"] == "arn:aws:logs:eu-west-2:852676506468:*"
    error_message = "Invalid value for aws_iam_policy_document log_policy.statement.condition.variable should be aws:SourceAccount and aws:SourceArn"
  }

  assert {
    condition     = jsondecode(data.aws_iam_policy_document.log-policy.json).Statement[0].Condition["StringEquals"]["aws:SourceAccount"] == "852676506468"
    error_message = "Invalid value for aws_iam_policy_document log_policy statement condition should be 852676506468"
  }

  assert {
    condition     = jsondecode(data.aws_iam_policy_document.log-policy.json).Statement[0].Principal.Service == "delivery.logs.amazonaws.com"
    error_message = "Invalid value for aws_iam_policy_document log_policy statement principal service should be delivery.logs.amazonaws.com"
  }

  assert {
    condition     = jsondecode(data.aws_iam_policy_document.log-policy.json).Statement[0].Resource == "arn:aws:logs:eu-west-2:852676506468:log-group:/copilot/log-test-application-log-test-environment-*:log-stream:*"
    error_message = "Invalid value for aws_iam_policy_document log_policy statement resource should be arn:aws:logs:eu-west-2:852676506468:log-group:/copilot/log-test-application-log-test-environment-*:log-stream:*"
  }
}

run "elasticache_log_policy_document_unit_test" {
  command = plan

  assert {
    condition     = jsondecode(data.aws_iam_policy_document.elasticache-log-policy.json).Statement[0].Condition["ArnLike"]["aws:SourceArn"] == "arn:aws:logs:eu-west-2:852676506468:*"
    error_message = "Invalid value for aws_iam_policy_document.elasticache-log-policy statement condition should be arn:aws:logs:eu-west-2:852676506468:*"
  }

  assert {
    condition     = jsondecode(data.aws_iam_policy_document.elasticache-log-policy.json).Statement[0].Principal.Service == "delivery.logs.amazonaws.com"
    error_message = "Invalid value for aws_iam_policy_document.elasticache-log-policy statement principal service should be delivery.logs.amazonaws.com"
  }

  assert {
    condition     = jsondecode(data.aws_iam_policy_document.elasticache-log-policy.json).Statement[0].Resource == "arn:aws:logs:eu-west-2:852676506468:log-group:/aws/elasticache/log-test-application/log-test-environment/*"
    error_message = "Invalid value for aws_iam_policy_document.elasticache-log-policy statement resource should be arn:aws:logs:eu-west-2:852676506468:log-group:/aws/elasticache/log-test-application/log-test-environment/*"
  }
}

run "opensearch_log_policy_document_unit_test" {
  command = plan

  assert {
    condition     = jsondecode(data.aws_iam_policy_document.opensearch-log-policy.json).Statement[0].Condition["StringEquals"]["aws:SourceAccount"] == "852676506468"
    error_message = "Invalid value for aws_iam_policy_document.opensearch-log-policy statement condition should be 852676506468"
  }

  assert {
    condition     = jsondecode(data.aws_iam_policy_document.opensearch-log-policy.json).Statement[0].Principal.Service == "es.amazonaws.com"
    error_message = "Invalid value for aws_iam_policy_document.opensearch-log-policy statement principal service should be es.amazonaws.com"
  }

  assert {
    condition     = jsondecode(data.aws_iam_policy_document.opensearch-log-policy.json).Statement[0].Resource == "arn:aws:logs:eu-west-2:852676506468:log-group:/aws/opensearch/log-test-application/log-test-environment/*"
    error_message = "Invalid value for aws_iam_policy_document.opensearch-log-policy statement resource should be arn:aws:logs:eu-west-2:852676506468:log-group:/aws/opensearch/log-test-application/log-test-environment/*"
  }
}
