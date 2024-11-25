data "aws_ssm_parameter" "slack_token" {
  name = "/codebuild/slack_oauth_token"
}

data "aws_ssm_parameter" "slack_alert_channel_alb_secret_rotation" {
  name = local.config_with_defaults.slack_alert_channel_alb_secret_rotation
}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "public-subnets" {
  filter {
    name   = "tag:Name"
    values = ["${var.vpc_name}-public-*"]
  }
}

resource "aws_lb" "this" {
  # checkov:skip=CKV2_AWS_20: Redirects for HTTP requests into HTTPS happens on the CDN
  # checkov:skip=CKV2_AWS_28: WAF is outside of terraform-platform-modules
  name               = "${var.application}-${var.environment}"
  load_balancer_type = "application"
  subnets            = tolist(data.aws_subnets.public-subnets.ids)
  security_groups = [
    aws_security_group.alb-security-group["http"].id,
    aws_security_group.alb-security-group["https"].id
  ]
  access_logs {
    bucket  = "dbt-access-logs"
    prefix  = "${var.application}/${var.environment}"
    enabled = true
  }

  tags = local.tags

  drop_invalid_header_fields = true
  enable_deletion_protection = true
}

resource "aws_lb_listener" "alb-listener" {
  # checkov:skip=CKV_AWS_2:Checkov Looking for Hard Coded HTTPS but we use a variable.
  # checkov:skip=CKV_AWS_103:Checkov Looking for Hard Coded TLS1.2 but we use a variable.
  depends_on = [aws_acm_certificate_validation.cert_validate]

  for_each          = local.protocols
  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = upper(each.key)
  ssl_policy        = each.value.ssl_policy
  certificate_arn   = each.value.certificate_arn
  tags              = local.tags
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http-target-group.arn
  }
}

resource "aws_security_group" "alb-security-group" {
  # checkov:skip=CKV2_AWS_5: False Positive in Checkov - https://github.com/bridgecrewio/checkov/issues/3010
  # checkov:skip=CKV_AWS_260: Ingress traffic from 0.0.0.0:0 is necessary to enable connecting to web services
  for_each    = local.protocols
  name        = "${var.application}-${var.environment}-alb-${each.key}"
  description = "Managed by Terraform"
  vpc_id      = data.aws_vpc.vpc.id
  tags        = local.tags
  ingress {
    description = "Allow from anyone on port ${each.value.port}"
    from_port   = each.value.port
    to_port     = each.value.port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow traffic out on port ${each.value.port}"
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "http-target-group" {
  # checkov:skip=CKV_AWS_261:Health Check is Defined by copilot
  name        = "${var.application}-${var.environment}-http"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.vpc.id
  tags        = local.tags
}

# Certificate will be referenced by its primary standard domain but we include all the CDN domains in the SAN field.
resource "aws_acm_certificate" "certificate" {
  domain_name               = local.domain_name
  subject_alternative_names = coalesce(try((keys(local.san_list)), null), [])
  validation_method         = "DNS"
  key_algorithm             = "RSA_2048"
  tags                      = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert_validate" {
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.validation-record-san : record.fqdn]
}

## End of Application Load Balancer section.


## Start of section that updates AWS R53 records in either the Dev or Prod AWS account, dependant on the provider aws.domain.

# This makes sure the correct root domain is selected for each of the certificate fqdn.
data "aws_route53_zone" "domain-root" {
  provider = aws.domain

  count = local.number_of_domains
  name  = local.full_list[tolist(aws_acm_certificate.certificate.domain_validation_options)[count.index].domain_name]
}

resource "aws_route53_record" "validation-record-san" {
  provider = aws.domain

  count   = local.number_of_domains
  zone_id = data.aws_route53_zone.domain-root[count.index].zone_id
  name    = tolist(aws_acm_certificate.certificate.domain_validation_options)[count.index].resource_record_name
  type    = tolist(aws_acm_certificate.certificate.domain_validation_options)[count.index].resource_record_type
  records = [tolist(aws_acm_certificate.certificate.domain_validation_options)[count.index].resource_record_value]
  ttl     = 300
}

# Add ALB DNS name to application internal DNS record.
data "aws_route53_zone" "domain-alb" {
  provider = aws.domain

  name = "${var.application}.${local.domain_suffix}"
}

resource "aws_route53_record" "alb-record" {
  provider = aws.domain

  zone_id = data.aws_route53_zone.domain-alb.zone_id
  name    = local.domain_name
  type    = "CNAME"
  records = [aws_lb.this.dns_name]
  ttl     = 300
}

# This is only run if there are additional application domains (not to be confused with CDN domains).
# Add ALB DNS name to applications additional domain.
resource "aws_route53_record" "additional-address" {
  provider = aws.domain

  count   = var.config.additional_address_list == null ? 0 : length(var.config.additional_address_list)
  zone_id = data.aws_route53_zone.domain-alb.zone_id
  name    = "${var.config.additional_address_list[count.index]}.${local.additional_address_domain}"
  type    = "CNAME"
  records = [aws_lb.this.dns_name]
  ttl     = 300
}


output "cert-arn" {
  value = aws_acm_certificate.certificate.arn
}

output "alb-arn" {
  value = aws_lb.this.arn
}


## This section configures WAF on ALB to attach security token.

data "aws_caller_identity" "current" {}

# Random password for the secret value
resource "random_password" "origin-secret" {
  length           = 32
  special          = false
  override_special = "_%@"
}

resource "aws_wafv2_web_acl" "waf-acl" {
  # checkov:skip=CKV2_AWS_31: Ensure WAF2 has a Logging Configuration to be done new ticket
  depends_on = [data.aws_secretsmanager_secret_version.origin_verify_secret_version, random_password.origin-secret]

  name        = "${var.application}-${var.environment}-ACL"
  description = "CloudFront Origin Verify"
  scope       = "REGIONAL"

  default_action {
    block {} # Action to perform if none of the rules contained in the WebACL match
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.application}-${var.environment}-XOriginVerify"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "${var.application}-${var.environment}-XOriginVerify"
    priority = "0"

    action {
      allow {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.application}-${var.environment}-XMetric"
      sampled_requests_enabled   = true
    }

    statement {
      or_statement {
        statement {
          byte_match_statement {
            field_to_match {
              single_header {
                name = "x-origin-verify"
              }
            }
            positional_constraint = "EXACTLY"
            search_string         = jsondecode(data.aws_secretsmanager_secret_version.origin_verify_secret_version.secret_string)["HEADERVALUE"]
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
        statement {
          byte_match_statement {
            field_to_match {
              single_header {
                name = "x-origin-verify"
              }
            }
            positional_constraint = "EXACTLY"
            search_string         = random_password.origin-secret.result
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }
  }

  # Add the Managed Rule Group for Log4j2 protection
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 1

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.application}-${var.environment}-WAF-ACL-ManagedBadInputs"
      sampled_requests_enabled   = true
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
  }

  lifecycle {
    # Use `ignore_changes` to allow rotation without Terraform overwriting the value
    ignore_changes = [rule]
  }
  tags = local.tags

}

# AWS Lambda Resources

# IAM Role for Lambda Execution
resource "aws_iam_role" "origin-secret-rotate-execution-role" {
  name = "${var.application}-${var.environment}-origin-secret-rotate-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  inline_policy {
    name = "OriginVerifyRotatePolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams"
          ]
          Resource = "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*origin-secret-rotate*"
        },
        {
          Effect = "Allow"
          Action = [
            "secretsmanager:DescribeSecret",
            "secretsmanager:GetSecretValue",
            "secretsmanager:PutSecretValue",
            "secretsmanager:UpdateSecretVersionStage"
          ]
          Resource = "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:*"
          
        },
        {
          Effect   = "Allow"
          Action   = ["secretsmanager:GetRandomPassword"]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "cloudfront:GetDistribution",
            "cloudfront:GetDistributionConfig",
            "cloudfront:ListDistributions",
            "cloudfront:UpdateDistribution"
          ]
          Resource = "arn:aws:cloudfront::${var.dns_account_id}:distribution/*"
        },
        {
          Effect   = "Allow"
          Action   = ["wafv2:*"]
          Resource = aws_wafv2_web_acl.waf-acl.arn
        },
        {
          Effect   = "Allow",
          Action   = ["sts:AssumeRole"]
          Resource = "arn:aws:iam::${var.dns_account_id}:role/dbt_platform_cloudfront_token_rotation"
        },
        {
          Effect   = "Allow",
          Action   = ["kms:Decrypt", "kms:DescribeKey", "kms:Encrypt"]
          Resource = aws_kms_key.origin_verify_secret_key.arn
        }
      ]
    })
  }
  tags = local.tags
}

# This file needs to exist, but it's not directly used in the Terraform so...
# tflint-ignore: terraform_unused_declarations
# This resource creates the Lambda function code zip file
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_function"
  output_path = "${path.module}/lambda_function.zip" # This zip contains only your function code
  excludes = [
    "**/.DS_Store",
    "**/.idea/*"
  ]

  depends_on = [
    aws_iam_role.origin-secret-rotate-execution-role
  ]
}


# Secrets Manager Rotation Lambda Function
resource "aws_lambda_function" "origin-secret-rotate-function" {
  # Precedence in the Postgres Lambda to skip first 2 checks
  # checkov:skip=CKV_AWS_272:Code signing is not currently in use
  # checkov:skip=CKV_AWS_116:Dead letter queue not required due to the nature of this function
  # checkov:skip=CKV_AWS_173:Encryption of environmental variables is not configured with KMS key
  # checkov:skip=CKV_AWS_117:Run Lambda inside VPC with security groups & private subnets not necessary
  # checkov:skip=CKV_AWS_50:XRAY tracing not used
  depends_on    = [data.archive_file.lambda]
  filename      = data.archive_file.lambda.output_path
  function_name = "${var.application}-${var.environment}-origin-secret-rotate"
  description   = "Secrets Manager Rotation Lambda Function"
  handler       = "rotate_secret_lambda.lambda_handler"
  runtime       = "python3.9"
  timeout       = 300
  role          = aws_iam_role.origin-secret-rotate-execution-role.arn
  # this is not a user-facing function that needs to scale rapidly
  reserved_concurrent_executions = 5

  environment {
    variables = {
      WAFACLID = aws_wafv2_web_acl.waf-acl.id
      # todo: why are we splitting on |, should it just be aws_wafv2_web_acl.waf-acl.name?
      WAFACLNAME    = split("|", aws_wafv2_web_acl.waf-acl.name)[0]
      WAFRULEPRI    = "0"
      DISTROIDLIST  = local.domain_list
      HEADERNAME    = "x-origin-verify"
      APPLICATION   = var.application
      ENVIRONMENT   = var.environment
      ROLEARN       = "arn:aws:iam::${var.dns_account_id}:role/dbt_platform_cloudfront_token_rotation"
      AWS_ACCOUNT   = data.aws_caller_identity.current.account_id
      SLACK_TOKEN   = data.aws_ssm_parameter.slack_token.value
      SLACK_CHANNEL = data.aws_ssm_parameter.slack_alert_channel_alb_secret_rotation.value
    }
  }

  layers           = ["arn:aws:lambda:eu-west-2:763451185160:layer:python-requests:1"]
  source_code_hash = data.archive_file.lambda.output_base64sha256
  tags             = local.tags
}

# Lambda Permission for Secrets Manager Rotation
resource "aws_lambda_permission" "rotate-function-invoke-permission" {
  statement_id  = "AllowSecretsManagerInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.origin-secret-rotate-function.function_name
  principal     = "secretsmanager.amazonaws.com"

  # chekov CKV_AWS_364 requirement: limit lambda invocation by secrets in the same AWS account
  source_account = data.aws_caller_identity.current.account_id
}


# Associate WAF ACL with ALB
resource "aws_wafv2_web_acl_association" "waf-alb-association" {
  resource_arn = aws_lb.this.arn
  web_acl_arn  = aws_wafv2_web_acl.waf-acl.arn
}
