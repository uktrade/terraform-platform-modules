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
    name            = string,
    engine          = optional(string),
    deletion_policy = optional(string),
    instances       = optional(number)
    instance        = optional(string),
    volume_size     = optional(number),
    master          = optional(bool)
  })

  validation {
    condition = length(var.config.name) <= 28
    error_message = "The name ${var.config.name} is too long at ${length(var.config.name)} chars. It must be at most 28 chars"
  }
}
