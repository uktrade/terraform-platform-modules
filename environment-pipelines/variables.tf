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
        accounts = object({
          deploy = object({
            name = string
            id   = string
          }),
          dns = object({
            name = string
            id   = string
          })
        })
        requires_approval = optional(bool)
      }
    )
  )
}

variable "branch" {
  type    = string
  default = "main"
}
