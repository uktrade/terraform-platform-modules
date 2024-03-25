variable "application" {
  type = string
}

variable "environment" {
  type = string
}

variable "name" {
  type = string
}

variable "config" {
  type = object({
    engine                     = optional(string)
    plan                       = optional(string)
    instance                   = optional(string)
    replicas                   = optional(number)
    apply_immediately          = optional(bool)
    automatic_failover_enabled = optional(bool)
    multi_az_enabled           = optional(bool)
  })
}
