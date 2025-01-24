
variable "config" {
  type = object({
    source_bucket_arn            = string
    source_kms_key_arn           = optional(string)
    worker_role_arn              = string
    additional_worker_role_arn   = optional(list(string))
    additional_source_bucket_arn = optional(list(string))
  })
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
