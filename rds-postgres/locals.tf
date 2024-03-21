locals {
  tags = {
    Application = var.application
    Environment = var.environment
  }

  name = "${var.application}-${var.environment}-${var.name}"

  version = var.config.version
  family = local.version != null ? format("postgres%d", local.version): null
  major_version = local.version != null ? tonumber(format("%d", local.version)) : null

  deletion_protection = coalesce(var.config.deletion_protection, false)
  multi_az = coalesce(var.config.multi_az, false)
# iops = optional(number)
  snapshot_id = var.config.snapshot_id
  volume_size = coalesce(var.config.volume_size, 20)

  instance = coalesce(var.config.instance, "db.t3.micro")
}