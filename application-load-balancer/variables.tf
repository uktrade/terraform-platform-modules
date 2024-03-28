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
    domains = string
    san_domains = optional(list(string))
    domains_list = map(string)
  })
}
