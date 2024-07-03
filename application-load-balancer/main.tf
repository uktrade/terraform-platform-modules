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

  drop_invalid_header_fields = true
  enable_deletion_protection = true
}

resource "aws_lb_listener" "alb-listener" {
  # checkov:skip=CKV_AWS_2:Checkov Looking for Hard Coded HTTPS but we use a variable.
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
  # checkov:skip=CKV2_AWS_5:Security group is used by VPC. Ticket to investigate: https://uktrade.atlassian.net/browse/DBTP-1039
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
