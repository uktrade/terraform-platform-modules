variable "application" {
  type = string
}

variable "environment" {
  type = string
}

variable "space" {
  type = string
}

variable "config" {
  type = object({
    name            = string,
    engine          = optional(string),
    deletion_policy = optional(string),
    plan            = optional(string),
    volume_size     = optional(number),
  })
}
