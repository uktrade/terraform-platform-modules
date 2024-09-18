locals {
  redis_engine_version_map = {
    "7.1" = "redis7"
    "7.0" = "redis7"
    "6.2" = "redis6.x"
  }
  central_log_destination_arn = "arn:aws:logs:eu-west-2:812359060647:destination:cwl_log_destination"
  tags = {
    application         = var.application
    environment         = var.environment
    managed-by          = "DBT Platform - Terraform"
    copilot-application = var.application
    copilot-environment = var.environment
  }
}
