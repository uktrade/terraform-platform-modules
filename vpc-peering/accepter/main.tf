# VPC
resource "aws_vpc_peering_connection_accepter" "this" {
  #provider                  = aws
  vpc_peering_connection_id = var.config.vpc_peering_connection_id
  auto_accept               = true

  tags = local.tags
}


data "aws_route_tables" "peering-table" {
  vpc_id = var.config.accepter_vpc

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

resource "aws_route" "peering-route" {
  count          = length(data.aws_route_tables.peering-table.ids)
  route_table_id = tolist(data.aws_route_tables.peering-table.ids)[count.index]

  # CIDR block / IP range for VPC 2.
  destination_cidr_block = var.config.requester_subnet

  # ID of VPC peering connection.
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.this.id
}

resource "aws_security_group_rule" "peer-access" {
  count             = var.config.security_group_id != null ? 1 : 0
  type              = "ingress"
  from_port         = var.config.port
  to_port           = var.config.port
  protocol          = "tcp"
  cidr_blocks       = [var.config.requester_subnet]
  security_group_id = var.config.security_group_id
  description       = "vpc peering from vpc: ${var.config.requester_vpc_name}"
}
