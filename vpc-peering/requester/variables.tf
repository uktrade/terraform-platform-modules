# variable "accepter_account_id" {
#   default = null
#   type    = string
# }

# variable "accepter_vpc" {
#   default = null
#   type    = string
# }

# variable "requester_vpc" {
#   default = null
#   type    = string
# }

variable "name" {
  default = null
  type    = string
}

# variable "arg_config" {
#   default = null
#   type    = map
# }

variable "config" {
  type = object({
    accepter_account_id = string
    accepter_vpc        = string
    accepter_vpc_name   = string
    requester_vpc       = string
    accepter_subnet     = string
    security_group_id   = optional(string)
    port                = optional(string)
  })
}
