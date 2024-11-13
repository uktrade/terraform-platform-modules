variable "application" {
  type = string
}

variable "codebase" {
  type = string
}

variable "repository" {
  type = string
}

variable "additional_ecr_repository" {
  type = string
}

variable "pipelines" {
  type = list(object(
    {
      name   = string
      branch = optional(string)
      tag    = optional(bool)
      environments = list(object(
        {
          name              = string
          requires_approval = optional(bool)
        }
      ))
    }
  ))
}

variable "services" {
  type = any
}

variable "environments" {
  type = any
}

variable "deploy_account" {
  type = string
}
