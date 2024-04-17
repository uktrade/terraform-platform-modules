
variable "name" {
  default = null
  type    = string
}

variable "config" {
  type = object({
    accepter_account_id = string
    accepter_vpc        = string
    accepter_vpc_name   = string
    requester_vpc       = string
    accepter_subnet     = string
    security_group_map  = optional(map(string))
  })
}
