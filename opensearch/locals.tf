locals {
  tags = {
    application         = var.application
    environment         = var.environment
    managed-by          = "DBT Platform - Terraform"
    copilot-application = var.application
    copilot-environment = var.environment
  }

  name               = replace(var.name, "_", "-")
  domain_name        = replace("${local.name}-${var.environment}", "_", "-")
  ssm_parameter_name = "/copilot/${local.name}/${var.environment}/secrets/OPENSEARCH_PASSWORD"

  master_user = "opensearch_user"

  instances              = coalesce(var.config.instances, 1)
  zone_awareness_enabled = local.instances > 1
  zone_count             = local.zone_awareness_enabled ? local.instances : null
  subnets                = slice(tolist(data.aws_subnets.private-subnets.ids), 0, local.instances)

  auto_tune_desired_state = startswith(var.config.instance, "t2") || startswith(var.config.instance, "t3") ? "DISABLED" : "ENABLED"
}
