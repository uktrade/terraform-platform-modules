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

resource "aws_lb" "this" {
  name               = "${var.application}-${var.environment}"
  load_balancer_type = "application"
  subnets            = tolist(data.aws_subnets.public-subnets.ids)
  security_groups    = [
    aws_security_group.alb-http.id,
    aws_security_group.alb-https.id
  ]
  tags = local.tags
}

resource "aws_lb_listener" "http-listener" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"
  tags              = local.tags

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http-target-group.arn
  }
}

resource "aws_lb_listener" "https-listener" {
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:eu-west-2:852676506468:certificate/fdbdea9a-5245-44ac-b22b-92ad8bacbca1"
  tags              = local.tags

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http-target-group.arn
  }
}

resource "aws_security_group" "alb-http" {
  name   = "${var.application}-${var.environment}-alb-http"
  vpc_id = data.aws_vpc.vpc.id
  tags   = local.tags
}

resource "aws_security_group" "alb-https" {
  name   = "${var.application}-${var.environment}-alb-https"
  vpc_id = data.aws_vpc.vpc.id
  tags   = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "allow-http-ingress" {
  security_group_id = aws_security_group.alb-http.id
  description       = "Allow from anyone on port 80"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  tags              = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "allow-https-ingress" {
  security_group_id = aws_security_group.alb-https.id
  description       = "Allow from anyone on port 443"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
  tags              = local.tags
}

resource "aws_vpc_security_group_egress_rule" "allow-http-egress" {
  security_group_id = aws_security_group.alb-http.id
  description       = "Allow traffic out on port 80"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  tags              = local.tags
}

resource "aws_vpc_security_group_egress_rule" "allow-https-egress" {
  security_group_id = aws_security_group.alb-https.id
  description       = "Allow traffic out on port 443"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
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

# Todo: Enable logging
