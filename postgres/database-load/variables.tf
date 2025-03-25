variable "application" {
  type = string
}

variable "environment" {
  type = string
}

variable "database_name" {
  type = string
}

variable "task" {
  type = object({
    from            = string
    to              = string
    from_account    = string
    to_account      = string
    to_prod_account = bool
    pipeline        = optional(object({}))
  })
}
