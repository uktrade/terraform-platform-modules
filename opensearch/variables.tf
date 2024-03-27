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
    name        = string,
    engine      = string,
    instances   = number,
    instance    = string,
    volume_size = number,
    master      = bool
  })

  validation {
    condition     = length(var.config.name) <= 28
    error_message = "The name ${var.config.name} is too long at ${length(var.config.name)} chars. It must be at most 28 chars"
  }
}
