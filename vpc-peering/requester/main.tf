resource "aws_vpc_peering_connection" "this" {
  peer_owner_id = var.config.accepter_account_id
  peer_vpc_id   = var.config.accepter_vpc
  vpc_id        = var.config.requester_vpc
  auto_accept   = true

  tags = local.tags
}

module "core" {
  source = "../core"

  vpc_id                    = var.config.requester_vpc
  subnet                    = var.config.accepter_subnet
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  security_group_map        = coalesce(var.config.security_group_map, {})
  vpc_name                  = var.config.accepter_vpc_name
}
