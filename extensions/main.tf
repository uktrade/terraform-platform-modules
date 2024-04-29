module "s3" {
  source = "../s3"

  for_each = local.s3

  application = var.args.application
  environment = var.environment
  name        = each.key
  vpc_name    = var.vpc_name

  config = each.value
}

module "postgres" {
  source = "../postgres"

  for_each = local.postgres

  application = var.args.application
  environment = var.environment
  name        = each.key
  vpc_name    = var.vpc_name

  config = each.value
}

module "elasticache-redis" {
  source = "../elasticache-redis"

  for_each = local.redis

  application = var.args.application
  environment = var.environment
  name        = each.key
  vpc_name    = var.vpc_name

  config = each.value
}

module "opensearch_test" {
  source = "../opensearch"

  for_each = local.opensearch

  application = var.args.application
  environment = var.environment
  name        = each.key
  vpc_name    = var.vpc_name

  config = each.value
}

module "alb" {
  source = "../application-load-balancer"

  for_each = local.alb
  providers = {
    aws.domain = aws.domain
  }
  application = var.args.application
  environment = var.environment
  vpc_name    = var.vpc_name

  config = each.value
}

module "monitoring" {
  source = "../monitoring"

  for_each = local.monitoring

  application = var.args.application
  environment = var.environment
  vpc_name    = var.vpc_name

  config = each.value
}

resource "aws_ssm_parameter" "addons" {
  name  = "/copilot/applications/${var.args.application}/environments/${var.environment}/addons"
  type  = "String"
  value = jsonencode(var.args.services)
  tags  = local.tags
}
