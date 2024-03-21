// Paramter group

resource "aws_rds_cluster_parameter_group" "cluster-parameter-group" {
  name        = local.name
  family      = local.family

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_parameter_group" "db-parameter-group" {
  name        = local.name
  family      = local.family

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# // Subnet group

resource "aws_db_subnet_group" "db-subnet-group" {
  name        = local.name
  subnet_ids  = data.aws_subnets.private-subnets.ids

  tags = local.tags
}

