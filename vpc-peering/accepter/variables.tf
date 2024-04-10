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
    vpc_peering_connection_id = string
    requester_vpc_name        = string
    accepter_vpc              = string
    requester_subnet          = string
    security_group_id         = optional(string)
    port                      = optional(string)
  })
}
