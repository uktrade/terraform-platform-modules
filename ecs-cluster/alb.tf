data "aws_lb" "environment_load_balancer" {
  name = "${var.application}-${var.environment}"
}

data "aws_lb_listener" "environment_alb_listener_https" {
  load_balancer_arn = data.aws_lb.environment_load_balancer.arn
  port              = 443
}

data "aws_lb_listener" "environment_alb_listener_http" {
  load_balancer_arn = data.aws_lb.environment_load_balancer.arn
  port              = 80
}

data "aws_security_group" "http_security_group" {
  name = "${var.application}-${var.environment}-alb-http"
}

data "aws_security_group" "https_security_group" {
  name = "${var.application}-${var.environment}-alb-https"
}

resource "aws_security_group" "environment_security_group" {

  name        = "${var.application}-${var.environment}-environment"
  description = "Managed by Terraform"
  vpc_id      = data.aws_vpc.vpc.id
  tags        = local.tags


  ingress {
    description = "Allow from ALB"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [
      data.aws_security_group.https_security_group.id
    ]
  }

  ingress {
    description = "Ingress from other containers in the same security group"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
  egress {
    description = "Allow traffic out"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_listener_rule" "https" {
  for_each = local.web_services

  listener_arn = data.aws_lb_listener.environment_alb_listener_https.arn
  priority     = coalesce(each.value.alb.alb_rule_priority, 100) + 10000

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group[each.key].arn
  }

  condition {
    host_header {
      values = coalesce(each.value.alb.alb_rule_alias, ["${each.key}.${var.environment}.${var.application}.uktrade.digital"])
    }
  }

  condition {
    path_pattern {
      values = coalesce(each.value.alb.alb_rule_path, ["/*"])
    }
  }

  tags = local.tags
}


resource "aws_lb_listener_rule" "http_to_https" {
  listener_arn = data.aws_lb_listener.environment_alb_listener_http.arn
  priority     = 1

  action {
    type = "redirect"
    redirect {
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  tags = local.tags
}


resource "aws_lb_target_group" "target_group" {
  for_each = local.web_services

  name        = "${var.application}-${var.environment}-${each.key}-tg"
  port        = 443
  protocol    = "HTTPS"
  target_type = "ip"
  vpc_id      = data.aws_vpc.vpc.id

  deregistration_delay = 60

  health_check {
    port                = coalesce(each.value.healthcheck.port, 8080)
    path                = coalesce(each.value.healthcheck.path, "/")
    protocol            = "HTTP"
    matcher             = coalesce(each.value.healthcheck.success_codes, "200")
    healthy_threshold   = coalesce(each.value.healthcheck.healthy_threshold, 3)
    unhealthy_threshold = coalesce(each.value.healthcheck.unhealthy_threshold, 3)
    interval            = tonumber(trim(coalesce(each.value.healthcheck.interval, "35s"), "s"))
    timeout             = tonumber(trim(coalesce(each.value.healthcheck.timeout, "30s"), "s"))
  }
}



