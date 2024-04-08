locals {
  tags = {
    Application = var.application
    Environment = var.environment
  }

  name = "${var.application}-${var.environment}-${var.name}"
}
