locals {
  tags = {
    application         = var.application
    environment         = var.environment
    managed-by          = "DBT Platform - Terraform"
    copilot-application = var.application
    copilot-environment = var.environment
  }

  protocols = {
    http = {
      port            = 80
      ssl_policy      = null
      certificate_arn = null
    }
    https = {
      port            = 443
      ssl_policy      = "ELBSecurityPolicy-2016-08"
      certificate_arn = aws_acm_certificate.certificate.arn
    }
  }

  secret_token_header_name   = "x-origin-verify"
  secret_token_rotation_days = 7

  # The primary domain for every application follows these naming standard.  See README.md 
  domain_prefix             = coalesce(var.config.domain_prefix, "internal")
  domain_suffix             = var.environment == "prod" ? coalesce(var.config.env_root, "prod.uktrade.digital") : coalesce(var.config.env_root, "uktrade.digital")
  domain_name               = var.environment == "prod" ? "${local.domain_prefix}.${var.application}.${local.domain_suffix}" : "${local.domain_prefix}.${var.environment}.${var.application}.${local.domain_suffix}"
  additional_address_domain = try(var.environment == "prod" ? "${var.application}.${local.domain_suffix}" : "${var.environment}.${var.application}.${local.domain_suffix}")

  # Create map of all items in address list with its base domain. eg { x.y.base.com: base.com }
  additional_address_fqdn = try({ for k in var.config.additional_address_list : "${k}.${local.additional_address_domain}" => "${var.application}.${local.domain_suffix}" }, {})

  # A List of domains that can be used in the Subject Alternative Name (SAN) part of the certificate.
  # Only select the domain from the value field of cdn_domains_list (drop "internal") 
  culled_san_list = try({ for k, v in var.config.cdn_domains_list : k => v[1] }, {})
  san_list        = merge(local.additional_address_fqdn, local.culled_san_list)

  # Create a complete domain list, primary domain plus all CDN/SAN domains.
  full_list = merge({ (local.domain_name) = "${var.application}.${local.domain_suffix}" }, local.san_list)

  # Count total number of domains.
  number_of_domains = length(local.full_list)
  domain_list       = lookup(var.config, "cdn_domains_list", null) != null ? join(",", keys(var.config.cdn_domains_list)) : ""

}
