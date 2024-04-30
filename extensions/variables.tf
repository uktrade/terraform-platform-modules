variable "args" {
  type = object({
    application = string,
    services    = any,
    dns_account_id = string
  })
}

variable "environment" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "dns_account_id" {
  type = string
}
