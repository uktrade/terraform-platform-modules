data "aws_vpc" "vpc" {
  #depends_on = [module.platform-vpc]
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "private-subnets" {
  filter {
    name   = "tag:Name"
    values = ["${var.vpc_name}-private-*"]
  }
}

data "aws_security_group" "base-sg" {
  filter {
    name   = "tag:Name"
    values = ["${var.vpc_name}-base-sg"]
  }
}

data "aws_caller_identity" "current" {}


resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.application}${var.environment}"
  description                = "${var.application}-${var.environment}-redis-cluster"
  engine                     = "redis"
  engine_version             = coalesce(var.config.engine, "7.1")
  node_type                  = coalesce(var.config.instance, "cache.t4g.micro")
  num_node_groups            = 1
  replicas_per_node_group    = coalesce(var.config.replicas, 1)
  parameter_group_name       = "default.${lookup(local.redis_engine_version_map, var.config.engine)}"
  port                       = 6379
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  apply_immediately          = coalesce(var.config.apply_immediately, false)
  subnet_group_name          = aws_elasticache_subnet_group.es-subnet-group.name
  security_group_ids         = [aws_security_group.redis-security-group.id]

  log_delivery_configuration {
    log_type         = "slow-log"
    destination      = aws_cloudwatch_log_group.redis_slow_log_group.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
  }

  log_delivery_configuration {
    log_type         = "engine-log"
    destination      = aws_cloudwatch_log_group.redis_engine_log_group.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
  }

  tags = local.tags
}

resource "aws_security_group" "redis-security-group" {
  name        = "${var.application}-${var.environment}-redis-sg"
  vpc_id      = data.aws_vpc.vpc.id
  description = "Allow ingress from VPC for Redis"

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [data.aws_security_group.base-sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags
}

resource "aws_ssm_parameter" "endpoint" {
  name        = "/copilot/${var.application}/${var.environment}/secrets/${upper(replace("${var.environment}-redis", "-", "_"))}"
  description = "redis endpoint"
  type        = "SecureString"
  value       = "rediss://${aws_elasticache_replication_group.redis.primary_endpoint_address}:6379"

  tags = local.tags
}

resource "aws_elasticache_subnet_group" "es-subnet-group" {
  name       = "${var.application}-${var.environment}-cache-subnet"
  subnet_ids = tolist(data.aws_subnets.private-subnets.ids)

  tags = merge(
    local.tags,
    {
      copilot-vpc = var.vpc_name
    }
  )
}

resource "aws_cloudwatch_log_group" "redis_slow_log_group" {
  name              = "/aws/elasticache/${var.application}/${var.environment}/${var.application}Redis/slow"
  retention_in_days = 7
  tags              = local.tags
}

resource "aws_cloudwatch_log_group" "redis_engine_log_group" {
  name              = "/aws/elasticache/${var.application}/${var.environment}/${var.application}Redis/engine"
  retention_in_days = 7
  tags              = local.tags
}

resource "aws_cloudwatch_log_subscription_filter" "demodjango_redis_subscription_filter_engine" {
  name           = "${var.application}-${var.environment}-filter-engine"
  role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CWLtoSubscriptionFilterRole"
  log_group_name = aws_cloudwatch_log_group.redis_engine_log_group.name
  filter_pattern  = ""
  destination_arn = local.central_log_destination_arn
}

resource "aws_cloudwatch_log_subscription_filter" "demodjango_redis_subscription_filter_slow" {
  name           = "${var.application}-${var.environment}-filter-slow"
  role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CWLtoSubscriptionFilterRole"
  log_group_name = aws_cloudwatch_log_group.redis_slow_log_group.name
  filter_pattern  = ""
  destination_arn = local.central_log_destination_arn
}

