locals {
  tags = {
    application         = var.application
    environment         = var.environment
    managed-by          = "DBT Platform - Terraform"
    copilot-application = var.application
    copilot-environment = var.environment
  }

  # The primary domain for every application follows these naming standard.  See README.md 
  domain_prefix = coalesce(var.config.domain_prefix, "internal")
  domain_suffix = var.environment == "prod" ? coalesce(var.config.env_root, "prod.uktrade.digital") : coalesce(var.config.env_root, "uktrade.digital")
  domain_name   = var.environment == "prod" ? "${local.domain_prefix}.${var.application}.${local.domain_suffix}" : "${local.domain_prefix}.${var.environment}.${var.application}.${local.domain_suffix}"

  # Default configuration for CDN.
  cdn_defaults = {
    viewer_protocol_policy = coalesce(var.config.viewer_protocol_policy, "redirect-to-https")
    viewer_certificate = {
      minimum_protocol_version = coalesce(var.config.viewer_certificate_minimum_protocol_version, "TLSv1.2_2021")
      ssl_support_method       = coalesce(var.config.viewer_certificate_ssl_support_method, "sni-only")
    }
    forwarded_values = {
      query_string = coalesce(var.config.forwarded_values_query_string, true)
      headers      = coalesce(var.config.forwarded_values_headers, ["*"])
      cookies = {
        forward = coalesce(var.config.forwarded_values_forward, "all")
      }
    }
    allowed_methods = coalesce(var.config.allowed_methods, ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"])
    cached_methods  = coalesce(var.config.cached_methods, ["GET", "HEAD"])

    origin = {
      custom_origin_config = {
        origin_protocol_policy = coalesce(var.config.origin_protocol_policy, "https-only")
        origin_ssl_protocols   = coalesce(var.config.origin_ssl_protocols, ["TLSv1.2"])
      }
    }
    compress = coalesce(var.config.cdn_compress, true)

    geo_restriction = {
      restriction_type = coalesce(var.config.cdn_geo_restriction_type, "none")
      locations        = coalesce(var.config.cdn_geo_locations, [])
    }

    logging_config = coalesce({
      include_cookies = false
      bucket          = var.config.cdn_logging_bucket
      prefix          = var.config.cdn_logging_bucket_prefix
    }, {})
    default_waf = var.environment == "prod" ? coalesce(var.config.default_waf, "waf_sentinel_684092750218_default") : coalesce(var.config.default_waf, "waf_sentinel_011755346992_default")
  }
}
