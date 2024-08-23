variable "application" {
  type    = string
  default = ""
}

variable "config" {
  type = object({
    role_arn       = string
    bucket_actions = list(string)
  })
}

variable "environment" {
  type    = string
  default = ""
}

variable "resource_arn" {
  type    = string
  default = ""
}