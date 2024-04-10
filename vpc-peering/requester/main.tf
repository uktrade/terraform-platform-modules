# VPC
resource "aws_vpc_peering_connection" "this" {
  peer_owner_id = var.config.accepter_account_id
  peer_vpc_id   = var.config.accepter_vpc
  vpc_id        = var.config.requester_vpc
  #auto_accept   = true

  tags = local.tags
}

# data "aws_vpc" "vpc" {
#   id = var.config.requester_vpc
# }

data "aws_route_tables" "peering-table" {
  vpc_id = var.config.requester_vpc

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

resource "aws_route" "peering-route" {
  count          = length(data.aws_route_tables.peering-table.ids)
  route_table_id = tolist(data.aws_route_tables.peering-table.ids)[count.index]

  # CIDR block / IP range for VPC 2.
  destination_cidr_block = var.config.accepter_subnet

  # ID of VPC peering connection.
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}


resource "aws_security_group_rule" "peer-access" {
  count             = var.config.security_group_id != null ? 1 : 0
  type              = "ingress"
  from_port         = var.config.port
  to_port           = var.config.port
  protocol          = "tcp"
  cidr_blocks       = [var.config.accepter_subnet]
  security_group_id = var.config.security_group_id
  description       = "vpc peering from vpc: ${var.config.accepter_vpc_name}"
}
