terraform {
  required_version = ">= 1.7.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
    }
  }
}

data "aws_route_tables" "peering-table" {
  vpc_id = var.vpc_id

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

# If Prod there will be more than one route table, due to 1 x NAT per AZ.
resource "aws_route" "peering-route" {
  count                     = length(data.aws_route_tables.peering-table.ids)
  route_table_id            = tolist(data.aws_route_tables.peering-table.ids)[count.index]
  destination_cidr_block    = var.subnet
  vpc_peering_connection_id = var.vpc_peering_connection_id
}

resource "aws_security_group_rule" "peer-access" {
  for_each          = var.security_group_map
  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = [var.subnet]
  security_group_id = each.key
  description       = "vpc peering from vpc: ${var.vpc_name}"
}
