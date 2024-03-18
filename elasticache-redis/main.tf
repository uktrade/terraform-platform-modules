data "aws_vpc" "vpc" {
  #depends_on = [module.platform-vpc]
  filter {
      name = "tag:Name"
      values = [var.args.space]
  }
}

data "aws_subnets" "private-subnets" {
  filter {
    name = "tag:Name"
    values = ["${var.args.space}-private-*"]
  }
}

resource "aws_elasticache_cluster" "cluster" {
  cluster_id           = "${var.args.application}-${var.args.environment}-redis-cluster"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = "cache.m4.large"
  # Todo (spike): Multi-AX etc
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  #Todo (spike): Add for each back in, but needs ES rebuilding.
  #subnet_group_name    = aws_elasticache_subnet_group.es-subnet-group[var.args.space].name
  subnet_group_name    = aws_elasticache_subnet_group.es-subnet-group.name
  security_group_ids   = [aws_security_group.redis-security-group.id]
  # Todo (spike): Can we do something to avoid repeating the tags block all over the place?
  # Yes, we can create a locals map for each env
  tags                 = {
    copilot-application = var.args.application
    copilot-environment = var.args.environment
    managed-by          = "Terraform"
  }
}

resource "aws_security_group" "redis-security-group" {
  name        = "${var.args.environment}-${var.args.environment}-redis-sg"
  vpc_id      = data.aws_vpc.vpc.id
  description = "Allow ingress from VPC"

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
  }
  tags = {
        copilot-application = var.args.application
        copilot-environment = var.args.environment
        managed-by = "Terraform"
  }
}

# Todo (spike): Log groups, subscription filters etc.

resource "aws_ssm_parameter" "endpoint" {
  name        = "/copilot/${var.args.name}/${var.args.environment}/secrets/${upper(replace("${var.args.environment}-redis", "-", "_"))}"
  description = "redis endpoint"
  type        = "SecureString"
  value       = "redis://${aws_elasticache_cluster.cluster.cache_nodes[0].address}:${aws_elasticache_cluster.cluster.cache_nodes[0].port}"

  tags = {
        copilot-application = var.args.application
        copilot-environment = var.args.environment
        managed-by = "Terraform"
  }
}

resource "aws_elasticache_subnet_group" "es-subnet-group" {
  #Todo (spike): Add for each back in, but needs ES rebuilding. 
  name       = "${var.args.space}-cache-subnet"
  subnet_ids =  tolist(data.aws_subnets.private-subnets.ids)

  tags = {
        copilot-space = var.args.space
        managed-by = "Terraform"
  }
}

