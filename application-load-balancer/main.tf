data "aws_vpc" "vpc" {
  filter {
    name = "tag:Name"
    values = [var.space]
  }
}

data "aws_subnets" "public-subnets" {
  filter {
    name = "tag:Name"
    values = ["${var.space}-public-*"]
  }
}

resource "aws_lb" "this" {
  name               = "${var.application}-${var.environment}"
  internal           = true
  load_balancer_type = "application"
  # security_groups    =
  subnets            = tolist(data.aws_subnets.public-subnets.ids)

  enable_deletion_protection = true

  # access_logs {
  #   bucket  =
  #   prefix  =
  #   enabled = true
  # }

  tags = local.tags
}
