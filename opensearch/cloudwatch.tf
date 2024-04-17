data "aws_ssm_parameter" "destination-arn" {
  name = "/copilot/tools/central_log_groups"
}

resource "aws_cloudwatch_log_subscription_filter" "opensearch_log_group_index_slow_logs" {
  name            = "/aws/opensearch/${var.application}/${var.environment}/${var.name}/opensearch_log_group_index_slow"
  role_arn        = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CWLtoSubscriptionFilterRole"
  log_group_name  = "/aws/opensearch/${local.filter_name}/opensearch_log_group_index_slow_logs"
  filter_pattern  = ""
  destination_arn = jsondecode(data.aws_ssm_parameter.destination-arn.value)["prod"]

  depends_on = [aws_cloudwatch_log_group.opensearch_log_group_index_slow_logs]
}

resource "aws_cloudwatch_log_subscription_filter" "opensearch_log_group_search_slow_logs" {
  name            = "/aws/opensearch/${var.application}/${var.environment}/${var.name}/opensearch_log_group_search_slow"
  role_arn        = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CWLtoSubscriptionFilterRole"
  log_group_name  = "/aws/opensearch/${local.filter_name}/opensearch_log_group_search_slow_logs"
  filter_pattern  = ""
  destination_arn = jsondecode(data.aws_ssm_parameter.destination-arn.value)["prod"]

  depends_on = [aws_cloudwatch_log_group.opensearch_log_group_search_slow_logs]
}

resource "aws_cloudwatch_log_subscription_filter" "opensearch_log_group_es_application_logs" {
  name            = "/aws/opensearch/${var.application}/${var.environment}/${var.name}/opensearch_log_group_es_application"
  role_arn        = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CWLtoSubscriptionFilterRole"
  log_group_name  = "/aws/opensearch/${local.filter_name}/opensearch_log_group_es_application_logs"
  filter_pattern  = ""
  destination_arn = jsondecode(data.aws_ssm_parameter.destination-arn.value)["prod"]

  depends_on = [aws_cloudwatch_log_group.opensearch_log_group_es_application_logs]
}

resource "aws_cloudwatch_log_subscription_filter" "opensearch_log_group_audit_logs" {
  name            = "/aws/opensearch/${var.application}/${var.environment}/${var.name}/opensearch_log_group_audit"
  role_arn        = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CWLtoSubscriptionFilterRole"
  log_group_name  = "/aws/opensearch/${local.filter_name}/openopensearch_log_group_audit_logssearch"
  filter_pattern  = ""
  destination_arn = jsondecode(data.aws_ssm_parameter.destination-arn.value)["prod"]

  depends_on = [aws_cloudwatch_log_group.opensearch_log_group_audit_logs]
}
