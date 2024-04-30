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

variable "branch" {
  type = string
  default = "main"
}

variable "aws_account_name" {
  type = string
}

variable "dns_account_id" {
  type = string
}
