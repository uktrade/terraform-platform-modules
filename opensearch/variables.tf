variable "application" {
  type = string
}

variable "environment" {
  type = string
}

variable "name" {
  type = string
  validation {
    condition     = length(var.name) <= 28
    error_message = "The name ${var.name} is too long at ${length(var.name)} chars. It must be at most 28 chars"
  }
}

variable "vpc_name" {
  type = string
}

variable "config" {
  type = object({
    name            = optional(string),
    engine          = string,
    instances       = number,
    instance        = string,
    volume_size     = number,
    master          = bool
    ebs_volume_type = optional(string)
    ebs_throughput  = optional(number)
  })

  validation {
    condition     = length(coalesce(var.config.name, "-")) <= 28
    error_message = "The name ${coalesce(var.config.name, "-")} is too long ${length(coalesce(var.config.name, "-"))} chars. It must be at most 28 chars"
  }

  validation {
    condition     = contains(["standard", "gp2", "gp3", "io1", "io2", "sc1", "st1"], coalesce(var.config.ebs_volume_type, "gp2"))
    error_message = "var.config.ebs_volume_type must be one of: standard, gp2, gp3, io1, io2, sc1 or st1"
  }
}
