variable "application" {
  type    = string
  default = ""
}

variable "config" {
  type = object({
    source_bucket_arn         = string
    source_kms_key_arn        = string
    migration_worker_role_arn = string
  })
}

variable "environment" {
  type    = string
  default = ""
}

variable "destination_bucket_arn" {
  type    = string
  default = ""
}

variable "destination_bucket_identifier" {
  type    = string
  default = ""
}

variable "destination_kms_key_arn" {
  type    = string
  default = ""
}