resource "random_string" "suffix" {
  length           = 8
  special          = false
}

locals {
  tags = {
    application         = var.application
    environment         = var.environment
    managed-by          = "DBT Platform (Terraform)"
    copilot-application = var.application
    copilot-environment = var.environment
  }

  name = "${var.application}-${var.environment}-${var.name}"

  version       = var.config.version
  family        = local.version != null ? format("postgres%d", floor(local.version)) : null
  major_version = local.version != null ? tonumber(format("%d", floor(local.version))) : null

  deletion_protection = coalesce(var.config.deletion_protection, false)
  multi_az            = coalesce(var.config.multi_az, false)

  skip_final_snapshot = coalesce(var.config.skip_final_snapshot, false)
  final_snapshot_identifier = !local.skip_final_snapshot ? "${local.name}-${random_string.suffix.result}" : null
  snapshot_id = var.config.snapshot_id
  volume_size = coalesce(var.config.volume_size, 20)

  # See: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Storage.html
  storage_type = coalesce(var.config.storage_type, "gp3")
  iops         = contains(["io1", "io2"], local.storage_type) ? var.config.iops : null

  instance_class = coalesce(var.config.instance, "db.t3.micro")
}
