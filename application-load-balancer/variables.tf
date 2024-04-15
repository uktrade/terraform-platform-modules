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
    cdn_domains_list        = optional(map(string))
    additional_address_list = optional(list(string))
  })
}
