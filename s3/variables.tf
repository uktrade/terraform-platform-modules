variable "application" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_name" {
  type = string
  default = "not-used"
}

variable "config" {
  type = object({
    bucket_name = string
    versioning  = bool
    retention_policy = optional(object({
      mode  = string
      days  = optional(number)
      years = optional(number)
    }))
    # NOTE: readonly access is managed by Copilot server addon s3 policy.
    readonly = optional(bool)
    objects = optional(list(object({
      body = string
      key  = string
    })))
  })
}
