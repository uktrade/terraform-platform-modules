variable "application" {
  type    = string
  default = ""
}

variable "config" {
  type = object({
    source_bucket_arn  = string
    importing_role_arn = string
  })
}

variable "environment" {
  type    = string
  default = ""
}

variable "bucket_arn" {
  type    = string
  default = ""
}

variable "bucket_name" {
  type    = string
  default = ""
}