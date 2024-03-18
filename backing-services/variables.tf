
# variable "vpc_name" {
#     type = string
# }

variable "application" {
  type = string
} 

variable "environment" {
  type = string
} 

variable "services" {
  type = any
}

variable "environments" {
  type = any
}
