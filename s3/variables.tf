variable "application" {
  type = string
}

variable "environment" {
  type = string
}

# Todo: DBTP-947 Do something better than having the dummy unused variable
# tflint-ignore: terraform_unused_declarations
variable "name" {
  type    = string
  default = "not-used"
}

# Todo: DBTP-947 Do something better than having the dummy unused variable
# tflint-ignore: terraform_unused_declarations
variable "vpc_name" {
  type    = string
  default = "not-used"
}

variable "config" {
  type = object({
    bucket_name = string
    versioning  = optional(bool)
    retention_policy = optional(object({
      mode  = string
      days  = optional(number)
      years = optional(number)
    }))
    lifecycle_rules = optional(list(object({
      filter_prefix   = string
      expiration_days = number
      enabled         = bool
      })
      )
    )
    # NOTE: readonly access is managed by Copilot server addon s3 policy.
    readonly = optional(bool)
    objects = optional(list(object({
      body = string
      key  = string
    })))
  })
}
