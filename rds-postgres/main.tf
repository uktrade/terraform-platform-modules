data "aws_vpc" "vpc" {
  filter {
      name = "tag:Name"
      values = [var.vpc_name]
  }
}

data "aws_subnets" "private-subnets" {
  filter {
    name = "tag:Name"
    values = ["${var.vpc_name}-private*"]
  }
}

resource "aws_security_group" "security-group" {
  name        = local.name
  vpc_id      = data.aws_vpc.vpc.id
  description = "Allow access from inside the VPC"

  ingress {
    description = "Local VPC access"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"

    cidr_blocks = [
      data.aws_vpc.vpc.cidr_block,
    ]
  }
  tags = local.tags
}

### DEBUG

output "test" {
  value = data.aws_subnets.private-subnets.ids
}  
### RETAIN TH

# data "aws_secretsmanager_secret" "secret" {
#   arn = module.this.db_instance_master_user_secret_arn
# }

# data "aws_secretsmanager_secret_version" "current" {
#   secret_id = data.aws_secretsmanager_secret.secret.id
# }

# resource "aws_ssm_parameter" "connection-string" {
#   name  = "/copilot/${var.application}/${var.environment}/secrets/${upper(replace("${var.name}-rds-postgres", "-", "_"))}"
#   type  = "SecureString"
#   value = jsonencode({
#     "username"=jsondecode(nonsensitive(data.aws_secretsmanager_secret_version.current.secret_string)).username,
#     "password"=urlencode(jsondecode(nonsensitive(data.aws_secretsmanager_secret_version.current.secret_string)).password),
#     "engine"="postgres",
#     "port"=module.this.db_instance_port,
#     "dbname"=module.this.db_instance_name,
#     "host"=split(":", module.this.db_instance_endpoint)[0]
#   })
#   tags = local.tags
# }



