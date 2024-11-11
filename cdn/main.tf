data "aws_wafv2_web_acl" "waf-default" {
  provider = aws.domain-cdn
  name     = local.cdn_defaults.default_waf
  scope    = "CLOUDFRONT"
}

resource "aws_acm_certificate" "certificate" {
  provider = aws.domain-cdn
  for_each = local.cdn_domains_list

  domain_name       = each.key
  validation_method = "DNS"
  key_algorithm     = "RSA_2048"
  tags              = local.tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert-validate" {
  provider                = aws.domain-cdn
  for_each                = local.cdn_domains_list
  certificate_arn         = aws_acm_certificate.certificate[each.key].arn
  validation_record_fqdns = [for record in aws_route53_record.validation-record : record.fqdn]
}

data "aws_route53_zone" "domain-root" {
  provider = aws.domain-cdn
  for_each = local.cdn_domains_list
  name     = each.value[1]
}

resource "aws_route53_record" "validation-record" {
  provider = aws.domain-cdn
  for_each = local.cdn_domains_list
  zone_id  = data.aws_route53_zone.domain-root[each.key].zone_id
  name     = tolist(aws_acm_certificate.certificate[each.key].domain_validation_options)[0].resource_record_name
  type     = tolist(aws_acm_certificate.certificate[each.key].domain_validation_options)[0].resource_record_type
  records  = [tolist(aws_acm_certificate.certificate[each.key].domain_validation_options)[0].resource_record_value]
  ttl      = 300
}

resource "aws_cloudfront_distribution" "standard" {
  # checkov:skip=CKV_AWS_305:This is managed in the application.
  # checkov:skip=CKV_AWS_310:No fail-over origin required.
  # checkov:skip=CKV2_AWS_32:Response headers policy not required.
  # checkov:skip=CKV2_AWS_47:WAFv2 WebACL rules are set in https://gitlab.ci.uktrade.digital/webops/terraform-waf
  depends_on = [aws_acm_certificate_validation.cert-validate]

  provider        = aws.domain-cdn
  for_each        = local.cdn_domains_list
  enabled         = true
  is_ipv6_enabled = true
  web_acl_id      = data.aws_wafv2_web_acl.waf-default.arn
  aliases         = [each.key]

  origin {
    domain_name = "${each.value[0]}.${local.domain_suffix}"
    origin_id   = "${each.value[0]}.${local.domain_suffix}"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = local.cdn_defaults.origin.custom_origin_config.origin_protocol_policy
      origin_ssl_protocols   = local.cdn_defaults.origin.custom_origin_config.origin_ssl_protocols
      origin_read_timeout    = local.cdn_defaults.origin.custom_origin_config.cdn_timeout_seconds
    }
  }

  default_cache_behavior {
    allowed_methods  = local.cdn_defaults.allowed_methods
    cached_methods   = local.cdn_defaults.cached_methods
    target_origin_id = "${each.value[0]}.${local.domain_suffix}"
    forwarded_values {
      query_string = local.cdn_defaults.forwarded_values.query_string
      headers      = local.cdn_defaults.forwarded_values.headers
      cookies {
        forward = local.cdn_defaults.forwarded_values.cookies.forward
      }
    }
    compress               = local.cdn_defaults.compress
    viewer_protocol_policy = local.cdn_defaults.viewer_protocol_policy
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate.certificate[each.key].arn
    minimum_protocol_version       = local.cdn_defaults.viewer_certificate.minimum_protocol_version
    ssl_support_method             = local.cdn_defaults.viewer_certificate.ssl_support_method
  }

  restrictions {
    geo_restriction {
      restriction_type = local.cdn_defaults.geo_restriction.restriction_type
      locations        = local.cdn_defaults.geo_restriction.locations
    }
  }

  dynamic "logging_config" {
    for_each = local.cdn_defaults.logging_config
    content {
      bucket          = local.cdn_defaults.logging_config.bucket
      include_cookies = false
      prefix          = each.key
    }
  }

  tags = local.tags
}

# This is only run if enable_cdn_record is set to true.
# Production default is false.
# Non prod this is true.
resource "aws_route53_record" "cdn-address" {
  provider = aws.domain-cdn

  for_each = local.cdn_records
  zone_id  = data.aws_route53_zone.domain-root[each.key].zone_id
  name     = each.key
  type     = "A"
  alias {
    name                   = aws_cloudfront_distribution.standard[each.key].domain_name
    zone_id                = aws_cloudfront_distribution.standard[each.key].hosted_zone_id
    evaluate_target_health = false
  }
}


# Create a CDN cache Policy

resource "aws_cloudfront_cache_policy" "cache_policy" {
  provider = aws.domain-cdn

  count = length(local.cache_policy_set) > 0 ? 1 : 0
  #for_each = local.cache_policy_name
  name        = var.config.cache_policy["name"] #local.cache_policy_name #each.value 
  comment     = "Cache policy created for ${var.application}"
  default_ttl = var.config.cache_policy["default_ttl"]
  max_ttl     = var.config.cache_policy["max_ttl"]
  min_ttl     = var.config.cache_policy["min_ttl"]
  
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = var.config.cache_policy["cookies_config"]
    }
    headers_config {
      header_behavior = var.config.cache_policy["header"]
    }
    # valiid query string behaviours are none, all, whitelist, allExcept
    # query string values can only be set if behaviour is whitelist or allExcept.
    query_strings_config {
      query_string_behavior = var.config.cache_policy["query_string_behavior"]
      
      dynamic query_strings {
        for_each = var.config.cache_policy["query_string_behavior"] == "whitelist" || var.config.cache_policy["query_string_behavior"] == "allExcept" ? [var.config.cache_policy_query_strings] : []
          content {
          items = query_strings.value
          }
      }
    }
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip = true
  }
}
