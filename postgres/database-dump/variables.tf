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
    from = string
    to   = string
  })
}
