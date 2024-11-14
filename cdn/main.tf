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

  for_each = coalesce(var.config.cache_policy, {})

  name        = "${each.key}-${var.application}-${var.environment}"
  comment     = "Cache policy created for ${var.application}"
  default_ttl = each.value["default_ttl"]
  max_ttl     = each.value["max_ttl"]
  min_ttl     = each.value["min_ttl"]
  
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = each.value["cookies_config"]

      dynamic cookies {
        for_each = each.value["cookies_config"] == "whitelist" || each.value["cookies_config"] == "allExcept" ? [each.value["cookie_list"]] : []
          content {
          items = cookies.value
          }
      }
    }
    headers_config {
      header_behavior = each.value["header"]

      dynamic headers {
        for_each = each.value["header"] == "whitelist" ? [each.value["headers_list"]] : []
          content {
          items = headers.value
          }
      }
    }
    # valiid query string behaviours are none, all, whitelist, allExcept
    # query string values can only be set if behaviour is whitelist or allExcept.
    query_strings_config {
      query_string_behavior = each.value["query_string_behavior"]
      
      dynamic query_strings {
        for_each = each.value["query_string_behavior"] == "whitelist" || each.value["query_string_behavior"] == "allExcept" ? [each.value["cache_policy_query_strings"]] : []
          content {
          items = query_strings.value
          }
      }
    }
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip = true
  }
}

# We do not cache requests, so leaving all config as default.
resource "aws_cloudfront_origin_request_policy" "origin_request_policy" {
  provider = aws.domain-cdn

  for_each = coalesce(var.config.origin_request_policy, {})
  
  name    = "${each.key}-${var.application}-${var.environment}"
  comment = "Origin request policy created for ${var.application}"
  cookies_config {
    cookie_behavior = "all"
  }
  headers_config {
    header_behavior = "allViewer"
  }
  query_strings_config {
    query_string_behavior = "all"
  }
}
