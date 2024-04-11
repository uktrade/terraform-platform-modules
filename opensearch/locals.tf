resource "random_string" "suffix" {
  length  = 8
  special = false
}

locals {
  tags = {
    application         = var.application
    environment         = var.environment
    managed-by          = "DBT Platform - Terraform"
    copilot-application = var.application
    copilot-environment = var.environment
  }

  name               = replace(var.name, "_", "-")
  domain_name        = substr(replace("${var.environment}-${local.name}", "_", "-"), 0, 28)
  ssm_parameter_name = "/copilot/${var.application}/${var.environment}/secrets/${upper(replace("${var.name}_OPENSEARCH_URI", "-", "_"))}"

  master_user = "opensearch_user"

  instances              = coalesce(var.config.instances, 1)
  zone_awareness_enabled = local.instances > 1
  zone_count             = local.zone_awareness_enabled ? local.instances : null
  subnets                = slice(tolist(data.aws_subnets.private-subnets.ids), 0, local.instances)

  auto_tune_desired_state = startswith(var.config.instance, "t2") || startswith(var.config.instance, "t3") ? "DISABLED" : "ENABLED"
}
