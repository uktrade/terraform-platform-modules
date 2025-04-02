data "aws_lb" "environment_load_balancer" {
  name = "${var.application}-${var.environment}"
}

data "aws_lb_listener" "environment_alb_listener" {
  load_balancer_arn = data.aws_lb.environment_load_balancer.arn
  port              = 443
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
    from_port = 0
    to_port = 0
    protocol    = "-1"
    security_groups = [ 
      data.aws_security_group.https_security_group,
      data.aws_security_group.http_security_group # TODO remove? As we redirect to https this may not be needed
      ]
  }

  ingress {
    description = "Ingress from other containers in the same security group"
    from_port = 0
    to_port = 0
    protocol    = "-1"
    self = true
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
   listener_arn = data.aws_lb_listener.environment_alb_listener.arn
   priority     = 100
   action {
     type             = "forward"
     target_group_arn = aws_lb_target_group.target_group.arn
   }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  condition {
    host_header {
      # TODO - What if the alias is updated in the service manifest? Would need to run terraform anyway?
      values = ["web.${var.environment}.${var.application}.uktrade.digital"]
    }
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "${var.application}-${var.environment}-tg-tf"
  port        = 443
  protocol    = "HTTPS"
  target_type = "ip"
  vpc_id      = data.aws_vpc.vpc.id

  deregistration_delay = 60

  # TODO - Healthcheck settings can be changed in the service-manifest.yml, how will this be updated?
  health_check {
    port                = 8080
    healthy_threshold   = 3
    interval            = 35
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = 30
    path                = "/"
    unhealthy_threshold = 3
  }
}

