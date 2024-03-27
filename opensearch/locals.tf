locals {
    tags = {
        Application = var.application
        Environment = var.environment
    }

    max_domain_length = 28
    raw_domain  = "${var.environment}-${var.config.name}"

    domain      =  length(local.raw_domain) <= local.max_domain_length ? local.raw_domain : substr(local.raw_domain, 0, local.max_domain_length)
    master_user = "opensearch_user"

    instances = coalesce(var.config.instances, 1)
    zone_awareness_enabled = local.instances > 1
    zone_count = local.zone_awareness_enabled ? local.instances : null
    subnets = slice(tolist(data.aws_subnets.private-subnets.ids), 0, local.instances)
}
