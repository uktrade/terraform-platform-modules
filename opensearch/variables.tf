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
    engine                            = string,
    instances                         = number,
    instance                          = string,
    volume_size                       = number,
    master                            = bool
    ebs_volume_type                   = optional(string)
    ebs_throughput                    = optional(number)
    index_slow_log_retention_in_days  = optional(number)
    search_slow_log_retention_in_days = optional(number)
    es_app_log_retention_in_days      = optional(number)
    audit_log_retention_in_days       = optional(number)
    password_special_characters       = optional(string)
    urlencode_password                = optional(bool)
  })

  validation {
    condition     = contains(["standard", "gp2", "gp3", "io1", "io2", "sc1", "st1"], coalesce(var.config.ebs_volume_type, "gp2"))
    error_message = "var.config.ebs_volume_type must be one of: standard, gp2, gp3, io1, io2, sc1 or st1"
  }
}
