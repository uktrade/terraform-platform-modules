variable "application" {
  type = string
}

variable "domains" {
  type = list(string)
}

variable "environment" {
  type = string
}

variable "vpc_name" {
  type = string
}
