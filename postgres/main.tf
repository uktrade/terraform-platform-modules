data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "private-subnets" {
  filter {
    name   = "tag:Name"
    values = ["${var.vpc_name}-private*"]
  }
}

resource "aws_security_group" "default" {
  name        = local.name
  vpc_id      = data.aws_vpc.vpc.id
  description = "Allow access from inside the VPC"
  tags        = local.tags

  ingress {
    description = "Local VPC access"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"

    cidr_blocks = [
      data.aws_vpc.vpc.cidr_block,
    ]
  }

  ingress {
    description = "Ingress from Lambda Functions to DB"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"

    self = true
  }

  ingress {
    description = "Ingress from Lambda Functions to Secrets Manager"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"

    self = true
  }

  egress {
    description = "Egress from DB to Lambda Functions"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"

    self = true
  }

  egress {
    description = "Egress from Secrets Manager to Lambda Functions"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"

    self = true
  }
}

# resource "aws_vpc_security_group_ingress_rule" "vpc_access" {
#   description       = "Local VPC access"
#   security_group_id = aws_security_group.default.id
#   from_port         = 5432
#   to_port           = 5432
#   ip_protocol       = "tcp"
#   cidr_ipv4         = data.aws_vpc.vpc.cidr_block
#   tags              = local.tags
#   depends_on        = [aws_security_group.default]
# }

# resource "aws_vpc_security_group_ingress_rule" "lambda_to_db" {
#   description                  = "Ingress from Lambda Functions to DB"
#   security_group_id            = aws_security_group.default.id
#   referenced_security_group_id = aws_security_group.default.id
#   from_port                    = 5432
#   to_port                      = 5432
#   ip_protocol                  = "tcp"
#   tags                         = local.tags
#   depends_on                   = [aws_security_group.default]
# }

# resource "aws_vpc_security_group_ingress_rule" "lambda_to_secrets" {
#   description                  = "Ingress from Lambda Functions to Secrets Manager"
#   security_group_id            = aws_security_group.default.id
#   referenced_security_group_id = aws_security_group.default.id
#   from_port                    = 443
#   to_port                      = 443
#   ip_protocol                  = "tcp"
#   tags                         = local.tags
#   depends_on                   = [aws_security_group.default]
# }

# resource "aws_vpc_security_group_egress_rule" "db_to_lambda" {
#   description                  = "Egress from DB to Lambda Functions"
#   security_group_id            = aws_security_group.default.id
#   referenced_security_group_id = aws_security_group.default.id
#   from_port                    = 5432
#   to_port                      = 5432
#   ip_protocol                  = "tcp"
#   tags                         = local.tags
#   depends_on                   = [aws_security_group.default]
# }

# resource "aws_vpc_security_group_egress_rule" "secrets_to_lambda" {
#   description                  = "Egress from Secrets Manager to Lambda Functions"
#   security_group_id            = aws_security_group.default.id
#   referenced_security_group_id = aws_security_group.default.id
#   from_port                    = 443
#   to_port                      = 443
#   ip_protocol                  = "tcp"
#   tags                         = local.tags
#   depends_on                   = [aws_security_group.default]
# }
