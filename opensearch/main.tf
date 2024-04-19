data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "opensearch_log_group_index_slow_logs" {
  name              = "/aws/opensearch/${local.domain_name}/index-slow"
  retention_in_days = coalesce(var.config.index_slow_log_retention_in_days, 7)
}

resource "aws_cloudwatch_log_group" "opensearch_log_group_search_slow_logs" {
  name              = "/aws/opensearch/${local.domain_name}/search-slow"
  retention_in_days = coalesce(var.config.search_slow_log_retention_in_days, 7)
}

resource "aws_cloudwatch_log_group" "opensearch_log_group_es_application_logs" {
  name              = "/aws/opensearch/${local.domain_name}/es-application"
  retention_in_days = coalesce(var.config.es_app_log_retention_in_days, 7)
}

resource "aws_cloudwatch_log_group" "opensearch_log_group_audit_logs" {
  name              = "/aws/opensearch/${local.domain_name}/audit"
  retention_in_days = coalesce(var.config.audit_log_retention_in_days, 7)
}

resource "aws_cloudwatch_log_resource_policy" "opensearch_log_group_policy" {
  policy_name     = "opensearch_log_group_policy"
  policy_document = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "es.amazonaws.com"
      },
      "Action": [
        "logs:PutLogEvents",
        "logs:PutLogEventsBatch",
        "logs:CreateLogStream"
      ],
      "Resource": "arn:aws:logs:*"
    }
  ]
}
CONFIG
}

resource "aws_security_group" "opensearch-security-group" {
  name        = local.domain_name
  vpc_id      = data.aws_vpc.vpc.id
  description = "Allow inbound HTTP traffic"

  ingress {
    description = "HTTP from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"

    cidr_blocks = [
      data.aws_vpc.vpc.cidr_block,
    ]
  }

  egress {
    description = "Allow traffic out on all ports"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  tags = local.tags
}

resource "random_password" "password" {
  length      = 32
  upper       = true
  special     = true
  lower       = true
  numeric     = true
  min_upper   = 1
  min_special = 1
  min_lower   = 1
  min_numeric = 1
}

resource "aws_opensearch_domain" "this" {
  domain_name    = local.domain_name
  engine_version = "OpenSearch_${var.config.engine}"

  depends_on = [
    aws_cloudwatch_log_group.opensearch_log_group_index_slow_logs,
    aws_cloudwatch_log_group.opensearch_log_group_search_slow_logs,
    aws_cloudwatch_log_group.opensearch_log_group_es_application_logs,
    aws_cloudwatch_log_group.opensearch_log_group_audit_logs
  ]

  cluster_config {
    dedicated_master_count   = 1
    dedicated_master_type    = var.config.master ? var.config.instance : null
    dedicated_master_enabled = var.config.master
    instance_type            = var.config.instance
    instance_count           = local.instances
    zone_awareness_enabled   = local.zone_awareness_enabled
    dynamic "zone_awareness_config" {
      for_each = local.zone_awareness_enabled ? [1] : []
      content {
        availability_zone_count = local.zone_count
      }
    }
  }

  advanced_security_options {
    enabled                        = true
    anonymous_auth_enabled         = false
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = local.master_user
      master_user_password = random_password.password.result
    }
  }

  encrypt_at_rest {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.config.volume_size
    volume_type = coalesce(var.config.ebs_volume_type, "gp2")
    throughput  = var.config.ebs_volume_type == "gp3" ? coalesce(var.config.ebs_throughput, 250) : null
  }

  auto_tune_options {
    desired_state       = local.auto_tune_desired_state
    rollback_on_disable = "DEFAULT_ROLLBACK"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_log_group_index_slow_logs.arn
    log_type                 = "INDEX_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_log_group_search_slow_logs.arn
    log_type                 = "SEARCH_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_log_group_es_application_logs.arn
    log_type                 = "ES_APPLICATION_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_log_group_audit_logs.arn
    log_type                 = "AUDIT_LOGS"
  }

  node_to_node_encryption {
    enabled = true
  }

  vpc_options {
    subnet_ids         = local.subnets
    security_group_ids = [aws_security_group.opensearch-security-group.id]
  }

  access_policies = <<CONFIG
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${local.domain_name}/*"
        }
    ]
}
CONFIG

  tags = local.tags
}

resource "aws_ssm_parameter" "this-master-user" {
  name        = local.ssm_parameter_name
  description = "opensearch_password"
  type        = "SecureString"
  value       = "https://${local.master_user}:${urlencode(random_password.password.result)}@${aws_opensearch_domain.this.endpoint}"

  tags = local.tags
}

data "aws_vpc" "vpc" {
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
