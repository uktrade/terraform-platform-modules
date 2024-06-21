variable "application" {
  type = string
}
# Todo: Do something better than having the dummy unused variable
# tflint-ignore: terraform_unused_declarations
variable "environment" {
  type    = string
  default = "not-used"
}
