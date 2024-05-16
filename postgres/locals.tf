resource "random_string" "suffix" {
  length  = 8
  special = false
}

locals {
  tags = {
    application         = var.application
    environment         = var.environment
    managed-by          = "DBT Platform - Terraform"
    copilot-application = var.application
    copilot-environment = var.environment
  }

  name = "${var.application}-${var.environment}-${var.name}"

  version = var.config.version
  family  = local.version != null ? format("postgres%d", floor(local.version)) : null

  multi_az = coalesce(var.config.multi_az, false)

  skip_final_snapshot       = coalesce(var.config.skip_final_snapshot, false)
  final_snapshot_identifier = !local.skip_final_snapshot ? "${local.name}-${random_string.suffix.result}" : null
  snapshot_id               = var.config.snapshot_id
  volume_size               = coalesce(var.config.volume_size, 20)

  instance_class = coalesce(var.config.instance, "db.t3.micro")
  storage_type   = coalesce(var.config.storage_type, "gp3")
  iops           = var.config.iops != null && local.storage_type != "gp3" ? var.config.iops : null

  secret_prefix                = upper(replace(var.name, "-", "_"))
  rds_master_secret_name       = "${local.secret_prefix}_RDS_MASTER_ARN"
  read_only_secret_name        = "${local.secret_prefix}_READ_ONLY_USER"
  application_user_secret_name = "${local.secret_prefix}_APPLICATION_USER"
}
