
variable "name" {
  default = null
  type    = string
}

variable "config" {
  type = object({
    accepter_account_id = string
    accepter_vpc        = string
    accepter_vpc_name   = string
    accepter_region     = optional(string)
    accepter_subnet     = string
    requester_vpc       = string
    security_group_map  = optional(map(string))
  })
}
