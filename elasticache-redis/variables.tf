# variable "vpc_cidr_blocks" {
#   type = list(string)
# }

# variable "subnet_group_name" {
#   type = string
# }

# variable "vpc_id" {
#   type = string
# }

variable "args" {
  default = null
  type    = any
}
