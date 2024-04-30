variable "args" {
  type = object({
    application = string,
    services    = any,
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
