locals {
  tags = {
    application = var.application
    environment = var.environment
    managed-by  = "DBT Platform - Terraform"
    copilot-application = var.application
    copilot-environment = var.environment
  }

  name               = replace(var.config.name, "_", "-")
  ssm_parameter_name = "/copilot/${local.name}/${var.environment}/secrets/${upper(replace("${local.name}-opensearch", "-", "_"))}"

  max_domain_length = 28
  raw_domain        = "${var.environment}-${local.name}"

  domain      = length(local.raw_domain) <= local.max_domain_length ? local.raw_domain : substr(local.raw_domain, 0, local.max_domain_length)
  master_user = "opensearch_user"

  instances              = coalesce(var.config.instances, 1)
  zone_awareness_enabled = local.instances > 1
  zone_count             = local.zone_awareness_enabled ? local.instances : null
  subnets                = slice(tolist(data.aws_subnets.private-subnets.ids), 0, local.instances)

  auto_tune_desired_state = startswith(var.config.instance, "t2") || startswith(var.config.instance, "t3") ? "DISABLED" : "ENABLED"
}
