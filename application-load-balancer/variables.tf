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
  })

  validation {
    condition = alltrue([
      for k, v in var.config.cdn_domains_list : ((length(k) <= 63) && (length(k) >= 3))
    ])
    error_message = "Items in cdn_domains_list should be between 3 and 63 characters long."
  }
}
