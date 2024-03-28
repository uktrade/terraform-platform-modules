terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
      configuration_aliases = [
        aws.sandbox,
        aws.dev
      ]
    }
  }
}


locals{
  protocols = {
    http = {
      port            = 80
      ssl_policy      = null
      certificate_arn = null
    }
    https = {
      port            = 443
      ssl_policy      = "ELBSecurityPolicy-2016-08"
      certificate_arn = "${aws_acm_certificate.certificate.arn}"
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
  protocol          = upper("${each.key}")
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
    description       = "Allow from anyone on port ${each.value.port}"
    from_port         = each.value.port
    to_port           = each.value.port
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
  }
  egress {
    description       = "Allow traffic out on port ${each.value.port}"
    protocol          = "tcp"
    from_port         = 0
    to_port           = 65535
    cidr_blocks       = ["0.0.0.0/0"]
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

resource "aws_acm_certificate" "certificate" {

  domain_name = var.config.domains
  subject_alternative_names = coalesce(var.config.san_domains, [])
  validation_method = "DNS"
  key_algorithm = "RSA_2048"
  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "r53-zone" {
  provider = aws.dev

  for_each = var.config.domains_list
  name     = each.value
}

data "aws_route53_zone" "dev-root" {
  provider = aws.dev

  name         = "uktrade.digital"
}

resource "aws_route53_record" "validation-record" {
  provider = aws.dev

  count = length(var.config.domains_list)
  zone_id = data.aws_route53_zone.r53-zone[tolist(aws_acm_certificate.certificate.domain_validation_options)[count.index].domain_name].zone_id
  name = tolist(aws_acm_certificate.certificate.domain_validation_options)[count.index].resource_record_name
  type = tolist(aws_acm_certificate.certificate.domain_validation_options)[count.index].resource_record_type
  records = [tolist(aws_acm_certificate.certificate.domain_validation_options)[count.index].resource_record_value]
  ttl = 300
}



# Code for multiple domains
# resource "aws_acm_certificate" "certificate-additional" {

#   for_each = coalesce(toset(var.config.additional-domains), [])
#   domain_name = each.value
#   validation_method = "DNS"
#   key_algorithm = "RSA_2048"
#   tags = local.tags

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_route53_record" "validation-record-additional" {
#   provider = aws.dev

#   #count = can( var.args.acm_certificate.dns_validation_route53_zone ) ? 1 : 0
#   for_each = coalesce(toset(var.config.additional-domains), [])
#   zone_id = data.aws_route53_zone.r53-zone.zone_id
#   name = tolist(aws_acm_certificate.certificate-additional[each.key].domain_validation_options)[0].resource_record_name
#   type = tolist(aws_acm_certificate.certificate-additional[each.key].domain_validation_options)[0].resource_record_type
#   records = [tolist(aws_acm_certificate.certificate-additional[each.key].domain_validation_options)[0].resource_record_value]
#   ttl = 300
# }

# resource "aws_lb_listener_certificate" "additional-https" {
#   depends_on = [ aws_acm_certificate.certificate-additional ]
#   for_each = coalesce(toset(var.config.additional-domains), [])
#   listener_arn    = aws_lb_listener.alb-listener["https"].arn
#   certificate_arn = aws_acm_certificate.certificate-additional[each.key].arn
# }
