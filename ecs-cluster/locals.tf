locals {
  tags = {
    application         = var.application
    environment         = var.environment
    managed-by          = "DBT Platform - Terraform"
    copilot-application = var.application
    copilot-environment = var.environment
  }

  region_account = "${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}"
  cluster_name = "${var.application}-${var.environment}-tf"
}
