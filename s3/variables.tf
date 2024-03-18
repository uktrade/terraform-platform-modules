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
  type     = object({
    bucket_name = string
    type = string
    deletion_policy = optional(string)
    retention_policy = optional(object({
      mode = string
      days = number
    }))
    readonly = optional(bool)
    objects = optional(list(object({
      body = string
      key = string
    })))
  })
}
