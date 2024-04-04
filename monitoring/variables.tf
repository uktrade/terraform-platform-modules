variable "application" {
  type = string
}

variable "environment" {
  type = string
}

variable "config" {
  type = object({
    enable_ops_center = bool
  })
}
