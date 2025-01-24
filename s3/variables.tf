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
      filter_prefix   = optional(string)
      expiration_days = number
      enabled         = bool
    })))
    # NOTE: allows access to S3 bucket from non-DBT Platform managed roles
    external_role_access = optional(map(object({
      role_arn          = string
      read              = bool
      write             = bool
      cyber_sign_off_by = string
    })))
    # NOTE: readonly access is managed by Copilot server addon s3 policy.
    readonly                = optional(bool)
    serve_static_content    = optional(bool, false)
    serve_static_param_name = optional(string)
    objects = optional(list(object({
      body         = string
      key          = string
      content_type = optional(string)
    })))

    # S3 to S3 data migration
    data_migration = optional(object({
      import = optional(object({
        source_bucket_arn            = string
        source_kms_key_arn           = optional(string)
        worker_role_arn              = string
        additional_worker_role_arn   = optional(list(string))
        additional_source_bucket_arn = optional(list(string))
      }))
      })
    )
  })

  validation {
    condition = var.config.external_role_access == null ? true : alltrue([
      for k, v in var.config.external_role_access : (can(regex("^[\\w\\-\\.]+@(businessandtrade.gov.uk|digital.trade.gov.uk)$", v.cyber_sign_off_by)))
      # ((length(k) <= 63) && (length(k) >= 3))
    ])
    error_message = "All instances of external_role_access must be approved by cyber, and a cyber rep's email address entered."
  }
}
