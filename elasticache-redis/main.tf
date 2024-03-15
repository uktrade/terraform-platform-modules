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
  for_each             = toset(var.args.environment)
  cluster_id           = "${var.args.application}-${each.value}-redis-cluster"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = "cache.m4.large"
  # Todo (spike): Multi-AX etc
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  #subnet_group_name    = data.aws_subnets.private-subnets.name
  subnet_group_name    = aws_elasticache_subnet_group.es-subnet-group.name
  # Todo (spike): Can we do something to avoid repeating the tags block all over the place?
  # Yes, we can create a locals map for each env
  tags                 = {
    copilot-application = var.args.application
    copilot-environment = "${each.value}"
    managed-by          = "Terraform"
  }
}

resource "aws_security_group" "redis-security-group" {
  for_each = toset(var.args.environment)

  name        = "${var.args.application}-${each.value}-redis-sg"
  vpc_id      = data.aws_vpc.vpc.id
  description = "Allow ingress from VPC"

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
  }
}

## Redis endpoint stored in SSM so that other `services` can retrieve the endpoint.
#demodjangoRedisEndpointAddressParam:
#  Type: AWS::SSM::Parameter
#  Properties:
#    Name: !Sub '/copilot/${App}/${Env}/secrets/DEMODJANGO_REDIS'   # Other services can retrieve the endpoint from this path.
#    Type: String
#    Value: !Sub
#      - 'rediss://${url}:${port}'
#      - url: !GetAtt 'demodjangoRedisReplicationGroup.PrimaryEndPoint.Address'
#    port: !GetAtt 'demodjangoRedisReplicationGroup.PrimaryEndPoint.Port'

# Todo (spike): Log groups, subscription filters etc.

resource "aws_ssm_parameter" "endpoint" {
  for_each = toset(var.args.environment)

  # This will be a problem if you have > 1 openswearch instance per environment
  name        = "/copilot/${var.args.application}/${each.value}/secrets/${upper(replace("${var.args.application}-redis", "-", "_"))}"
  description = "redis endpoint"
  type        = "SecureString"
#  value       = "rediss://${aws_elasticache_cluster.cluster[each.value].endpoint}"
  value       = "redis://${aws_elasticache_cluster.cluster[each.key].cache_nodes[0].address}:${aws_elasticache_cluster.cluster[each.key].cache_nodes[0].port}"

  tags = {
        copilot-application = var.args.application
        copilot-environment = "${each.value}"
        managed-by = "Terraform"
  }
}

resource "aws_elasticache_subnet_group" "es-subnet-group" {
  #Todo (spike): Add for each back in, but needs ES rebuilding.
  #for_each = try (local.addons_map.redis, false) ? toset([var.args.space]) : []
  name       = "${var.args.space}-cache-subnet"
  subnet_ids =  tolist(data.aws_subnets.private-subnets.ids)

  tags = {
    copilot-space = var.args.space
    managed-by = "Terraform"
  }
}

