terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}


# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "${var.arg_value.cidr}${local.vpc_cidr_mask}"
  enable_dns_hostnames = true
  tags = {
    Name       = var.arg_key
    managed-by = "Terraform"
  }
}


# Subnets
##Private
resource "aws_subnet" "private" {
  for_each          = var.arg_value.az_map.private
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "${var.arg_value.cidr}.${each.value}${local.subnet_cidr_mask}"
  availability_zone = "${local.region}${each.key}"
  tags = {
    Name        = "${var.arg_key}-private-${local.region}${each.key}"
    subnet_type = "private"
    managed-by  = "Terraform"
  }
}


##Public
resource "aws_subnet" "public" {
  for_each          = var.arg_value.az_map.public
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "${var.arg_value.cidr}.${each.value}${local.subnet_cidr_mask}"
  availability_zone = "${local.region}${each.key}"
  tags = {
    Name        = "${var.arg_key}-public-${local.region}${each.key}"
    subnet_type = "public"
    managed-by  = "Terraform"
  }
}


## Public - Internet Gateway
resource "aws_internet_gateway" "public" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name       = "${var.arg_key}-ig-public"
    managed-by = "Terraform"
  }
}

# Public Routing
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name       = "${var.arg_key}-rt-public"
    managed-by = "Terraform"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.public.id
}

resource "aws_route_table_association" "public" {
  for_each       = var.arg_value.az_map.public
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}


# NAT Gateway
resource "aws_eip" "public" {
  for_each = toset(var.arg_value.nat_gateways)
  domain   = "vpc"
  tags = {
    Name       = "${var.arg_key}nat-eip-${each.key}"
    managed-by = "Terraform"
  }
}

resource "aws_nat_gateway" "public" {
  for_each      = toset(var.arg_value.nat_gateways)
  allocation_id = aws_eip.public[each.key].id
  subnet_id     = aws_subnet.public[each.key].id
  tags = {
    Name       = "${var.arg_key}-nat-gateway-${each.key}"
    managed-by = "Terraform"
  }
}


# Private Routing
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name       = "${var.arg_key}-rt-private"
    managed-by = "Terraform"
  }
}

resource "aws_route" "private_route" {
  for_each               = toset(var.arg_value.nat_gateways)
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.public[each.key].id
}

resource "aws_route_table_association" "private" {
  for_each       = var.arg_value.az_map.private
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private.id
}


# Default ACL
resource "aws_default_network_acl" "deafult-acl" {
  default_network_acl_id = aws_vpc.vpc.default_network_acl_id
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}
