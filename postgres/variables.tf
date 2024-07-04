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
    version               = number
    deletion_protection   = optional(bool)
    volume_size           = optional(number)
    iops                  = optional(number)
    snapshot_id           = optional(string)
    skip_final_snapshot   = optional(string)
    multi_az              = optional(bool)
    instance              = optional(string)
    storage_type          = optional(string)
    restore_time          = optional(string)
    backup_retention_days = optional(number)
  })
}

