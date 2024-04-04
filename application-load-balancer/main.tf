terraform {
  required_version = ">= 1.7.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>4.66.0"
      configuration_aliases = [
        aws.sandbox,
        aws.dev,
        aws.prod,
      ]
    }
  }
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
}

resource "aws_lb_listener" "alb-listener" {
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
  for_each = local.protocols
  name     = "${var.application}-${var.environment}-alb-${each.key}"
  vpc_id   = data.aws_vpc.vpc.id
  tags     = local.tags
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
  subject_alternative_names = coalesce(try((keys(var.config.cdn_domains_list)), null), [])
  validation_method         = "DNS"
  key_algorithm             = "RSA_2048"
  tags                      = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

################################################################
# Dev R53 account - Will only be run for non-production domains.

# This makes sure the correct root domain is selected for each of the certificate fqdn.
data "aws_route53_zone" "domain-root" {
  provider = aws.dev

  count = local.number_of_non_production_domains
  name  = local.full_list[tolist(aws_acm_certificate.certificate.domain_validation_options)[count.index].domain_name]
}

resource "aws_route53_record" "validation-record-san" {
  provider = aws.dev

  count   = local.number_of_non_production_domains
  zone_id = data.aws_route53_zone.domain-root[count.index].zone_id
  name    = tolist(aws_acm_certificate.certificate.domain_validation_options)[count.index].resource_record_name
  type    = tolist(aws_acm_certificate.certificate.domain_validation_options)[count.index].resource_record_type
  records = [tolist(aws_acm_certificate.certificate.domain_validation_options)[count.index].resource_record_value]
  ttl     = 300
}

# Add ALB DNS name to application internal DNS record.
data "aws_route53_zone" "domain-alb" {
  provider = aws.dev

  count = local.only_create_for_non_production
  name  = "${var.application}.${local.domain_suffix}"
}

resource "aws_route53_record" "alb-record" {
  provider = aws.dev

  count   = local.only_create_for_non_production
  zone_id = data.aws_route53_zone.domain-alb[0].zone_id
  name    = local.domain_name
  type    = "CNAME"
  records = [aws_lb.this.dns_name]
  ttl     = 300
}


#########################################################
# Prod R53 account - Will only run for production domains.

data "aws_route53_zone" "domain-root-prod" {
  provider = aws.prod

  count = local.number_of_production_domains
  name  = local.full_list[tolist(aws_acm_certificate.certificate.domain_validation_options)[count.index].domain_name]
}

# This makes sure the correct root domain is selected for each of the certificate fqdn.
resource "aws_route53_record" "validation-record-prod" {
  provider = aws.prod

  count   = local.number_of_production_domains
  zone_id = data.aws_route53_zone.domain-root-prod[0].zone_id
  name    = tolist(aws_acm_certificate.certificate.domain_validation_options)[count.index].resource_record_name
  type    = tolist(aws_acm_certificate.certificate.domain_validation_options)[count.index].resource_record_type
  records = [tolist(aws_acm_certificate.certificate.domain_validation_options)[count.index].resource_record_value]
  ttl     = 300
}

# Add ALB DNS name to application internal DNS record.
data "aws_route53_zone" "domain-alb-prod" {
  provider = aws.prod

  count = local.only_create_for_production
  name  = "${var.application}.${local.domain_suffix}"
}

resource "aws_route53_record" "alb-record-prod" {
  provider = aws.prod

  count   = local.only_create_for_production
  zone_id = data.aws_route53_zone.domain-alb-prod[0].zone_id
  name    = local.domain_name
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
