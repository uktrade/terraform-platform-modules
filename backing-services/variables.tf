variable args {
  type = object({
    application = string,
    services = any,
  })
}

variable "environment" {
  type = string
}

variable "vpc" {
  type = string
} 


