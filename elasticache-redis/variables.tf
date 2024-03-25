variable "application" {
  type = string
}

variable "environment" {
  type = string
}

variable "name" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "config" {
  type = object({
    engine            = optional(string)
    plan              = optional(string)
    instance          = optional(string)
    replicas          = optional(number)
    apply_immediately = optional(bool)
  })
}
