locals {
  redis_engine_version_map = {
    "7.1"    = "redis7"
    "7.0"    = "redis7"
    "6.2"    = "redis6.x"
    "6.0"    = "redis6.x"
    "5.0.6"  = "redis5.0"
    "5.0.4"  = "redis5.0"
    "5.0.3"  = "redis5.0"
    "5.0.0"  = "redis5.0"
    "4.0.10" = "redis4.0"
    "3.2.6"  = "redis3.2"
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
