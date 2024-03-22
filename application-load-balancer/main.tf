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

data "aws_acm_certificate" "certificate" {
  domain = var.domains[0]
}

locals {
  protocols = {
    http = {
      port            = 80
      ssl_policy      = null
      certificate_arn = null
    }
    https = {
      port            = 443
      ssl_policy      = "ELBSecurityPolicy-2016-08"
      certificate_arn = "${data.aws_acm_certificate.certificate.arn}"
    }
  }
  log_types = [
    "access",
    "connection"
  ]
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
    bucket  = aws_s3_bucket.alb-log-bucket.id
    prefix  = "access"
    enabled = true
  }
  connection_logs {
    bucket  = aws_s3_bucket.alb-log-bucket.id
    prefix  = "connection"
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
}

resource "aws_vpc_security_group_ingress_rule" "alb-allow-ingress" {
  for_each          = local.protocols
  security_group_id = aws_security_group.alb-security-group["${each.key}"].id
  description       = "Allow from anyone on port ${each.value.port}"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = each.value.port
  ip_protocol       = "tcp"
  to_port           = each.value.port
  tags              = local.tags
}

resource "aws_vpc_security_group_egress_rule" "alb-allow-egress" {
  for_each          = local.protocols
  security_group_id = aws_security_group.alb-security-group["${each.key}"].id
  description       = "Allow traffic out on port ${each.value.port}"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 0
  to_port           = 65535
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

resource "aws_s3_bucket" "alb-log-bucket" {
  bucket = "${var.application}-${var.environment}-alb-logs"
  tags   = local.tags
}

resource "aws_s3_bucket_policy" "alb-log-bucket-policy" {
  bucket = aws_s3_bucket.alb-log-bucket.id
  policy = data.aws_iam_policy_document.alb-log-bucket-policy-document.json
}

data "aws_elb_service_account" "main" {}

data "aws_iam_policy_document" "alb-log-bucket-policy-document" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.main.arn]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.alb-log-bucket.arn,
      "${aws_s3_bucket.alb-log-bucket.arn}/*"
    ]
  }
}
