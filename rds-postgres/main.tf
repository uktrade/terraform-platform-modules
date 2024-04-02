module "security-group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.args.application}-${var.args.environment}-rds-postgres-sg"
  description = "Complete PostgreSQL example security group"
  vpc_id      = data.aws_vpc.vpc.id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = data.aws_vpc.vpc.cidr_block
    },
  ]

  tags = {
    copilot-application = var.args.application
    copilot-environment = var.args.environment
    managed-by          = "Terraform"
  }
}


module "this" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${var.args.application}-${var.args.environment}-rds-postgres"

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine               = "postgres"
  engine_version       = "14"
  family               = "postgres14" # DB parameter group
  major_engine_version = "14"         # DB option group
  instance_class       = "db.t4g.large"

  allocated_storage     = 20
  max_allocated_storage = 100

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  db_name  = "completePostgresql"
  username = "complete_postgresql"
  port     = 5432

  # setting manage_master_user_password_rotation to false after it
  # has been set to true previously disables automatic rotation
  manage_master_user_password_rotation = false
  # master_user_password_rotate_immediately           = false
  # master_user_password_rotation_schedule_expression = "rate(15 days)"

  multi_az               = false
  create_db_subnet_group = true
  vpc_security_group_ids = [module.security-group.security_group_id]
  subnet_ids             = data.aws_subnets.private-subnets.ids

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60
  monitoring_role_name                  = "example-monitoring-role-name"
  monitoring_role_use_name_prefix       = true
  monitoring_role_description           = "Description for monitoring role"

  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]

  tags = {
    copilot-application = var.args.application
    copilot-environment = var.args.environment
    managed-by          = "Terraform"
  }

  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }
}

data "aws_vpc" "vpc" {
  #depends_on = [module.platform-vpc]
  filter {
    name   = "tag:Name"
    values = [var.args.space]
  }
}

data "aws_subnets" "private-subnets" {
  filter {
    name   = "tag:Name"
    values = ["${var.args.space}-private-*"]
  }
}

data "aws_secretsmanager_secret" "secret" {
  arn = module.this.db_instance_master_user_secret_arn
}

data "aws_secretsmanager_secret_version" "current" {
  secret_id = data.aws_secretsmanager_secret.secret.id
}

resource "aws_ssm_parameter" "connection-string" {
  name = "/copilot/${var.args.application}/${var.args.environment}/secrets/${upper(replace("${var.args.name}-rds-postgres", "-", "_"))}"
  type = "SecureString"
  value = jsonencode({
    "username" = jsondecode(nonsensitive(data.aws_secretsmanager_secret_version.current.secret_string)).username,
    "password" = urlencode(jsondecode(nonsensitive(data.aws_secretsmanager_secret_version.current.secret_string)).password),
    "engine"   = "postgres",
    "port"     = module.this.db_instance_port,
    "dbname"   = module.this.db_instance_name,
    "host"     = split(":", module.this.db_instance_endpoint)[0]
  })
  tags = {
    copilot-application = var.args.application
    copilot-environment = var.args.environment
    managed-by          = "Terraform"
  }
}
