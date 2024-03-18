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
    # NOTE: Deletion policy is not supported in Terrafo
    deletion_policy = optional(string)
    retention_policy = optional(object({
      mode = string
      days = optional(number)
      years = optional(number)
    }))
    versioning = optional(bool)
    # NOTE: readonly = true/false is handled by a policy attached to the ECS task role and managed by Copilot
    readonly = optional(bool)  
    objects = optional(list(object({
      body = string
      key = string
    })))
  })
}
