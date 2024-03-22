locals {
  tags = {
    Application = var.application
    Environment = var.environment
  }

  name = "${var.application}-${var.environment}-${var.name}"

  version       = var.config.version
  family        = local.version != null ? format("postgres%d", local.version) : null
  major_version = local.version != null ? tonumber(format("%d", local.version)) : null

  deletion_protection = coalesce(var.config.deletion_protection, false)
  multi_az            = coalesce(var.config.multi_az, false)

  snapshot_id = var.config.snapshot_id
  volume_size = coalesce(var.config.volume_size, 20)

  # See: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Storage.html
  storage_type = coalesce(var.config.storage_type, "gp3")
  iops         = coalesce(var.config.iops, 1000)

  instance_class = coalesce(var.config.instance, "db.t3.micro")
}