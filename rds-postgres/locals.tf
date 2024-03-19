locals {
  tags = {
    Application = var.application
    Environment = var.environment
  }

  name = "${var.application}-${var.environment}-${var.name}"

  version = coalesce(var.config.version, 14)
  deletion_protection = coalesce(var.config.deletion_protection, false)
  multi_az = coalesce(var.config.multi_az, false)
# iops = optional(number)
  snapshot_id = var.config.snapshot_id
  volume_size = coalesce(var.config.volume_size, 20)

  instance = coalesce(var.config.instance, "db.t3.micro")
}