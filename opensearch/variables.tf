# variable "vpc_id" {
#     type = string
# }

# variable "subnet_ids" {
#     type = list
# }

variable "security_options_enabled" { type = bool }
variable "volume_type" {
  type = string
}
variable "throughput" {
  type = number
}
variable "ebs_enabled" {
  type = bool
}
variable "ebs_volume_size" {
  type = number
}
variable "instance_type" { type = string }
variable "instance_count" { type = number }
variable "dedicated_master_enabled" {
  type    = bool
  default = false
}
variable "dedicated_master_count" {
  type    = number
  default = 0
}
variable "dedicated_master_type" {
  type    = string
  default = null
}
variable "zone_awareness_enabled" {
  type    = bool
  default = false
}
variable "engine_version" {
  type = string
}

variable "args" {
  default = null
  type    = any
}
