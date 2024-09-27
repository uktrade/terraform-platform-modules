variable "application" {
  type = string
}

variable "environment" {
  type = string
}

variable "job_name" {
  type = string
}

variable "config" {
  type = object({
    from = string
    to   = string
  })
}
