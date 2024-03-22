resource "aws_db_parameter_group" "default" {
  name   = local.name
  family = local.family

  tags = local.tags

  parameter {
    name  = "client_encoding"
    value = "utf8"
  }

  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  parameter {
    name  = "log_statement_sample_rate"
    value = "1.0"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "default" {
  name       = local.name
  subnet_ids = data.aws_subnets.private-subnets.ids

  tags = local.tags
}

resource "aws_kms_key" "default" {
  description = "${local.name} KMS key"
}

resource "aws_db_instance" "default" {

  identifier = local.name

  db_name                     = "main"
  username                    = "postgres"
  manage_master_user_password = true
  # master_user_secret_kms_key_id ?
  multi_az = local.multi_az

  # version
  engine         = "postgres"
  engine_version = local.version
  instance_class = local.instance_class

  # upgrades
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = true
  apply_immediately           = false
  maintenance_window          = "Mon:00:00-Mon:03:00"

  # storage
  allocated_storage = local.volume_size
  storage_encrypted = true
  kms_key_id        = aws_kms_key.default.arn

  parameter_group_name = aws_db_parameter_group.default.name
  db_subnet_group_name = aws_db_subnet_group.default.name

  backup_retention_period = 0
  backup_window           = "07:00-09:00"

  vpc_security_group_ids              = [aws_security_group.default.id]
  publicly_accessible                 = false
  iam_database_authentication_enabled = false

  #   snapshot_identifier         = var.snapshot_identifier
  #   skip_final_snapshot         = var.skip_final_snapshot
  #   copy_tags_to_snapshot       = var.copy_tags_to_snapshot
  #   final_snapshot_identifier   = length(var.final_snapshot_identifier) > 0 ? var.final_snapshot_identifier : module.final_snapshot_label.id

  enabled_cloudwatch_logs_exports = ["postgresql"]
  #   performance_insights_enabled          = var.performance_insights_enabled
  #   performance_insights_kms_key_id       = var.performance_insights_enabled ? var.performance_insights_kms_key_id : null
  #   performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  #   monitoring_interval = var.monitoring_interval
  #   monitoring_role_arn = var.monitoring_role_arn

  depends_on = [
    aws_db_subnet_group.default,
    aws_security_group.default,
    aws_db_parameter_group.default,
  ]

  tags = local.tags
}
