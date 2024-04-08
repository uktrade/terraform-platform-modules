variable "application" {
  type = string
}

variable "environment" {
  type = string
}

variable "name" {
  type = string
}

# Todo: Do something better than having the dummy unused variable
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
    # NOTE: readonly access is managed by Copilot server addon s3 policy.
    readonly = optional(bool)
    objects = optional(list(object({
      body = string
      key  = string
    })))
  })
}
