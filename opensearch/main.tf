data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# data "aws_vpc" "selected" {
#   id = var.vpc_id
# }

# resource "aws_cloudwatch_log_group" "opensearch_log_group_index_slow_logs" {
#   for_each = toset(var.args.environment)


#   name              = "/aws/opensearch/${local.domain}/index-slow"
#   retention_in_days = 14
# }

# resource "aws_cloudwatch_log_group" "opensearch_log_group_search_slow_logs" {
#   for_each = toset(var.args.environment)


#   name              = "/aws/opensearch/${local.domain}/search-slow"
#   retention_in_days = 14
# }

# resource "aws_cloudwatch_log_group" "opensearch_log_group_es_application_logs" {
#   for_each = toset(var.args.environment)

#   name              = "/aws/opensearch/${local.domain}/es-application"
#   retention_in_days = 14
# }

resource "aws_security_group" "opensearch-security-group" {
  name        = "${var.args.name}-${var.args.environment}--opensearch-sg"
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
  tags = {
        copilot-application = var.args.application
        copilot-environment = var.args.environment
        managed-by = "Terraform"
  }
}

resource "random_password" "password" {
  length  = 32
  special = true
}

resource "aws_opensearch_domain" "this" {
  # ToDo: Stupid 28 character limit, need to check and randamize name
  domain_name    = "${var.args.name}-engine"
  engine_version = "OpenSearch_${var.engine_version}"

  cluster_config {
    dedicated_master_count   = var.dedicated_master_count
    dedicated_master_type    = var.dedicated_master_type
    dedicated_master_enabled = var.dedicated_master_enabled
    instance_type            = var.instance_type
    instance_count           = var.instance_count
    zone_awareness_enabled   = var.zone_awareness_enabled
    # zone_awareness_config {
    #   availability_zone_count = var.zone_awareness_enabled ? length(tolist(data.aws_subnets.private-subnets.ids)) : null
    # }
    # zone_awareness_config {
    #   availability_zone_count = 3
    # }
  }

  advanced_security_options {
    enabled                        = var.security_options_enabled
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

  # domain_endpoint_options {
  #   enforce_https       = true
  #   tls_security_policy = "Policy-Min-TLS-1-2-2019-07"

  #   custom_endpoint_enabled         = true
  #   custom_endpoint                 = local.custom_domain
  #   custom_endpoint_certificate_arn = data.aws_acm_certificate.opensearch.arn
  # }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  ebs_options {
    ebs_enabled = var.ebs_enabled
    volume_size = var.ebs_volume_size
    volume_type = var.volume_type
    throughput  = var.throughput
  }

  # log_publishing_options {
  #   cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_log_group_index_slow_logs.arn
  #   log_type                 = "INDEX_SLOW_LOGS"
  # }
  # log_publishing_options {
  #   cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_log_group_search_slow_logs.arn
  #   log_type                 = "SEARCH_SLOW_LOGS"
  # }
  # log_publishing_options {
  #   cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_log_group_es_application_logs.arn
  #   log_type                 = "ES_APPLICATION_LOGS"
  # }

  node_to_node_encryption {
    enabled = true
  }

  vpc_options {
    # We get this error when deploying a single instance and supplying the full list of subnet IDs:
    #  Error: creating OpenSearch Domain: ValidationException: You must specify exactly one subnet.
    #subnet_ids = [local.instance_subnet_id]
    subnet_ids = [tolist(data.aws_subnets.private-subnets.ids)[0]]

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
            "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.args.name}-engine/*"
        }
    ]
}
CONFIG

tags = {
        copilot-application = var.args.application
        copilot-environment = var.args.environment
        managed-by = "Terraform"
  }
}

resource "aws_ssm_parameter" "this-master-user" {
  # This will be a problem if you have > 1 openswearch instance per environment
  name        = "/copilot/${var.args.name}/${var.args.environment}/secrets/${upper(replace("${var.args.name}-opensearch", "-", "_"))}"
  description = "opensearch_password"
  type        = "SecureString"
  value       = "https://${local.master_user}:${urlencode(random_password.password.result)}@${aws_opensearch_domain.this.endpoint}"

  tags = {
        copilot-application = var.args.application
        copilot-environment = var.args.environment
        managed-by = "Terraform"
  }
}

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