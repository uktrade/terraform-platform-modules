variable "application" {
  type = string
}

variable "repository" {
  type = string
}

variable "environments" {
  type = list(
    object(
      {
        name = string,
        requires_approval = optional(bool)
      }
    )
  )
}