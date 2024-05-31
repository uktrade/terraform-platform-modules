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

data "aws_caller_identity" "current" {}


resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.name}-${var.environment}"
  description                = "${var.name}-${var.environment}-redis-cluster"
  engine                     = "redis"
  engine_version             = var.config.engine
  node_type                  = coalesce(var.config.instance, "cache.t4g.micro")
  num_node_groups            = 1
  replicas_per_node_group    = coalesce(var.config.replicas, 1)
  parameter_group_name       = "default.${local.redis_engine_version_map[var.config.engine]}"
  port                       = 6379
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  apply_immediately          = coalesce(var.config.apply_immediately, false)
  automatic_failover_enabled = coalesce(var.config.automatic_failover_enabled, false)
  multi_az_enabled           = coalesce(var.config.multi_az_enabled, false)
  subnet_group_name          = aws_elasticache_subnet_group.es-subnet-group.name
  security_group_ids         = [aws_security_group.redis.id]

  log_delivery_configuration {
    log_type         = "slow-log"
    destination      = aws_cloudwatch_log_group.redis-slow-log-group.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
  }

  log_delivery_configuration {
    log_type         = "engine-log"
    destination      = aws_cloudwatch_log_group.redis-engine-log-group.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
  }

  tags = local.tags
}

resource "aws_security_group" "redis" {
  name        = "${var.name}-${var.environment}-redis-security-group"
  vpc_id      = data.aws_vpc.vpc.id
  description = "Allow ingress from VPC for Redis"

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags
}

resource "aws_kms_key" "ssm_redis_endpoint" {
  description             = "KMS key for SSM parameters"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = local.tags

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "kms-key-ssm-redis-endpoint",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow SSM Use of the Key",
      "Effect": "Allow",
      "Principal": {
        "Service": "ssm.amazonaws.com"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_ssm_parameter" "endpoint_short" {
  name        = "/copilot/${var.application}/${var.environment}/secrets/${upper(replace(var.name, "-", "_"))}"
  description = "Redis endpoint (Deprecated in favour of endpoint_ssl which has the ssl_cert_reqs parameter baked in)"
  type        = "SecureString"
  value       = "rediss://${aws_elasticache_replication_group.redis.primary_endpoint_address}:6379"

  tags = local.tags

  key_id = aws_kms_key.ssm_redis_endpoint.arn
}

resource "aws_ssm_parameter" "endpoint" {
  name        = "/copilot/${var.application}/${var.environment}/secrets/${upper(replace("${var.name}_ENDPOINT", "-", "_"))}"
  description = "Redis endpoint (Deprecated in favour of endpoint_ssl which has the ssl_cert_reqs parameter baked in)"
  type        = "SecureString"
  value       = "rediss://${aws_elasticache_replication_group.redis.primary_endpoint_address}:6379"

  tags = local.tags

  key_id = aws_kms_key.ssm_redis_endpoint.arn
}

resource "aws_elasticache_subnet_group" "es-subnet-group" {
  name       = "${var.name}-${var.environment}-cache-subnet"
  subnet_ids = tolist(data.aws_subnets.private-subnets.ids)

  tags = merge(
    local.tags,
    {
      copilot-vpc = var.vpc_name
    }
  )
}

resource "aws_cloudwatch_log_group" "redis-slow-log-group" {
  name              = "/aws/elasticache/${var.name}/${var.environment}/${var.name}Redis/slow"
  retention_in_days = 7
  tags              = local.tags
}

resource "aws_cloudwatch_log_group" "redis-engine-log-group" {
  name              = "/aws/elasticache/${var.name}/${var.environment}/${var.name}Redis/engine"
  retention_in_days = 7
  tags              = local.tags
}

resource "aws_cloudwatch_log_subscription_filter" "redis-subscription-filter-engine" {
  name            = "/aws/elasticache/${var.name}/${var.environment}/engine"
  role_arn        = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CWLtoSubscriptionFilterRole"
  log_group_name  = aws_cloudwatch_log_group.redis-engine-log-group.name
  filter_pattern  = ""
  destination_arn = local.central_log_destination_arn
}

resource "aws_cloudwatch_log_subscription_filter" "redis-subscription-filter-slow" {
  name            = "/aws/elasticache/${var.name}/${var.environment}/slow"
  role_arn        = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CWLtoSubscriptionFilterRole"
  log_group_name  = aws_cloudwatch_log_group.redis-slow-log-group.name
  filter_pattern  = ""
  destination_arn = local.central_log_destination_arn
}

