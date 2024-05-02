data "aws_wafv2_web_acl" "waf-default" {
  provider = aws.domain-cdn
  name     = local.cdn_defaults.default_waf
  scope    = "CLOUDFRONT"
}

resource "aws_acm_certificate" "certificate" {
  provider = aws.domain-cdn
  for_each = var.config.cdn_domains_list

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
  for_each                = var.config.cdn_domains_list
  certificate_arn         = aws_acm_certificate.certificate[each.key].arn
  validation_record_fqdns = [for record in aws_route53_record.validation-record : record.fqdn]
}

data "aws_route53_zone" "domain-root" {
  provider = aws.domain-cdn
  for_each = var.config.cdn_domains_list
  name     = each.value
}

resource "aws_route53_record" "validation-record" {
  provider = aws.domain-cdn
  for_each = var.config.cdn_domains_list
  zone_id  = data.aws_route53_zone.domain-root[each.key].zone_id
  name     = tolist(aws_acm_certificate.certificate[each.key].domain_validation_options)[0].resource_record_name
  type     = tolist(aws_acm_certificate.certificate[each.key].domain_validation_options)[0].resource_record_type
  records  = [tolist(aws_acm_certificate.certificate[each.key].domain_validation_options)[0].resource_record_value]
  ttl      = 300
}

resource "aws_cloudfront_distribution" "standard" {
  depends_on = [aws_acm_certificate_validation.cert-validate]

  provider        = aws.domain-cdn
  for_each        = var.config.cdn_domains_list
  enabled         = true
  is_ipv6_enabled = true
  web_acl_id      = data.aws_wafv2_web_acl.waf-default.arn
  aliases = [each.key]

  origin {
    domain_name = local.domain_name
    origin_id   = local.domain_name
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = local.cdn_defaults.origin.custom_origin_config.origin_protocol_policy
      origin_ssl_protocols   = local.cdn_defaults.origin.custom_origin_config.origin_ssl_protocols
    }
  }
  
  default_cache_behavior {
    allowed_methods  = local.cdn_defaults.allowed_methods
    cached_methods   = local.cdn_defaults.cached_methods
    target_origin_id = local.domain_name
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
    for_each = can( var.config.logging_config ) ? var.config.logging_config : local.cdn_defaults.logging_config
    content {
      bucket = try(
        logging_config.value.bucket,
        local.defaults.logging_config[0].bucket
      )
      include_cookies = try(
        logging_config.value.include_cookies,
        local.defaults.logging_config[0].include_cookies,
        false
      )
      prefix = try(
        logging_config.value.prefix,
        local.defaults.logging_config[0].prefix,
        null
      )
    }
  }

  tags = local.tags
}

