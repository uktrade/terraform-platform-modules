data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = [var.space]
  }
}

data "aws_subnets" "public-subnets" {
  filter {
    name   = "tag:Name"
    values = ["${var.space}-public-*"]
  }
}

# Todo: This should probably come from outside the module, Should we just pass the domain in from demodjango.tf?
data "aws_acm_certificate" "certificate" {
  domain = "v2.demodjango.${var.environment}.uktrade.digital"
}

locals {
  protocols = {
    http = {
      port            = 80,
      ssl_policy      = null
      certificate_arn = null
    },
    https = {
      port            = 443,
      ssl_policy      = "ELBSecurityPolicy-2016-08"
      certificate_arn = "${data.aws_acm_certificate.certificate.arn}"
    }
  }
}

resource "aws_lb" "this" {
  name               = "${var.application}-${var.environment}"
  load_balancer_type = "application"
  subnets            = tolist(data.aws_subnets.public-subnets.ids)
  security_groups    = [
    aws_security_group.alb-security-group["http"].id,
    aws_security_group.alb-security-group["https"].id
  ]
  tags = local.tags
  # Todo: Enable logging
}

resource "aws_lb_listener" "alb-listener" {
  for_each = local.protocols
  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = upper("${each.key}")
  ssl_policy        = "${each.value.ssl_policy}"
  certificate_arn   = "${each.value.certificate_arn}"
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
}

resource "aws_vpc_security_group_ingress_rule" "alb-allow-ingress" {
  for_each = local.protocols
  security_group_id = aws_security_group.alb-security-group["${each.key}"].id
  description       = "Allow from anyone on port ${each.value.port}"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = each.value.port
  ip_protocol       = "tcp"
  to_port           = each.value.port
  tags              = local.tags
}

resource "aws_vpc_security_group_egress_rule" "alb-allow-egress" {
  for_each = local.protocols
  security_group_id = aws_security_group.alb-security-group["${each.key}"].id
  description       = "Allow traffic out on port ${each.value.port}"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = each.value.port
  ip_protocol       = "tcp"
  to_port           = each.value.port
  tags              = local.tags
}

resource "aws_lb_target_group" "http-target-group" {
  name        = "${var.application}-${var.environment}-http"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.vpc.id
  tags        = local.tags
}
