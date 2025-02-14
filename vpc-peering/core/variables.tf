variable "vpc_id" {
  type = string
}

variable "subnet" {
  type = string
}

variable "vpc_peering_connection_id" {
  type = string
}

variable "security_group_map" {
  type = map(string)
}

variable "vpc_name" {
  type = string
}

variable "source_vpc" {
  type = string
}

variable "target_zone" {
  type = string
}

variable "accept_remote_dns" {
  type = bool
}
