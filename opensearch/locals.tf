locals {
  # tags = {
  #     Application = var.application
  #     Environment = var.environment
  #     Name = var.name
  # }

    max_domain_length = 28
    raw_domain  = "${var.environment}-${var.config.name}"

    domain      =  length(local.raw_domain) <= local.max_domain_length ? local.raw_domain : substr(local.raw_domain, 0, local.max_domain_length)
    master_user = "opensearch_user"
}
