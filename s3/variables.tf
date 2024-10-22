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
    cross_account_access_role = optional(string)
    versioning  = optional(bool)
    retention_policy = optional(object({
      mode  = string
      days  = optional(number)
      years = optional(number)
    }))
    lifecycle_rules = optional(list(object({
      filter_prefix   = optional(string)
      expiration_days = number
      enabled         = bool
      })
      )
    )
    # NOTE: readonly access is managed by Copilot server addon s3 policy.
    readonly             = optional(bool)
    serve_static_content = optional(bool, false)
    objects = optional(list(object({
      body         = string
      key          = string
      content_type = optional(string)
    })))

    # S3 to S3 data migration
    data_migration = optional(object({
      import = optional(object({
        source_bucket_arn  = string
        source_kms_key_arn = optional(string)
        worker_role_arn    = string
      }))
      })
    )
  })
}
