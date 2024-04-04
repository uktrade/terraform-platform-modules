variable "application" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_name" {
  type    = string
  default = "not-used"
}

variable "config" {
  type = object({
    enable_ops_center = bool
  })
}
