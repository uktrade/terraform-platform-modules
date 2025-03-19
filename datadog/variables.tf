variable "application" {
  type = string
}

variable "environment" {
  type = string
}

# Todo: Do something better than having the dummy unused variable
# tflint-ignore: terraform_unused_declarations
variable "vpc_name" {
  type    = string
  default = "not-used"
}

variable "config" {
  type = object({
    team_name = string
    contact_name = string
    contact_email = string
    repository = string
  })
}
