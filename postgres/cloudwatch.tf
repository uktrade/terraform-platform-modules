
data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_log_subscription_filter" "rds" {
  name            = "/aws/rds/instance/${var.application}/${var.environment}/${var.name}/postgresql"
  role_arn        = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CWLtoSubscriptionFilterRole"
  log_group_name  = "/aws/rds/instance/${local.name}/postgresql"
  filter_pattern  = ""
  destination_arn = "arn:aws:logs:eu-west-2:812359060647:destination:cwl_log_destination"

  depends_on = [aws_db_instance.default]
}
