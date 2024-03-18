variable "vpc_name" {
  type = string
}

variable "application" {
  type = string
}

variable "environment" {
  type = string
}

variable "config" {
  default = null
  type    = any
}
