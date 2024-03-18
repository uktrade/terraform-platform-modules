variable "application" {
  type = string
} 

variable "environment" {
  type = string
}

variable "name" {
  type = string
}

variable "vpc_name" {
  type = string
} 

variable "config" {
  default     = null
  type        = any
}
