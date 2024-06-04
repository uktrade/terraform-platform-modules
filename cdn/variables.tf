variable "application" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "config" {
  type = object({
    domain_prefix           = optional(string)
    env_root                = optional(string)
    cdn_domains_list        = optional(map(list(string)))
    additional_address_list = optional(list(string))
    enable_cdn_record       = optional(bool)
    enable_logging          = optional(bool)

    # CDN default overrides
    viewer_certificate_minimum_protocol_version = optional(string)
    viewer_certificate_ssl_support_method       = optional(string)
    forwarded_values_query_string               = optional(bool)
    forwarded_values_headers                    = optional(list(string))
    forwarded_values_forward                    = optional(string)
    viewer_protocol_policy                      = optional(string)
    allowed_methods                             = optional(list(string))
    cached_methods                              = optional(list(string))
    default_waf                                 = optional(string)
    origin_protocol_policy                      = optional(string)
    origin_ssl_protocols                        = optional(list(string))
    cdn_compress                                = optional(bool)
    cdn_geo_restriction_type                    = optional(string)
    cdn_geo_locations                           = optional(list(string))
    cdn_logging_bucket                          = optional(string)
    cdn_logging_bucket_prefix                   = optional(string)
  })
}
