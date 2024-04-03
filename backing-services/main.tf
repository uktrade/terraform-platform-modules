module "s3" {
  source = "../s3"

  for_each = local.s3

  application = var.args.application
  environment = var.environment
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

module "opensearch" {
  source = "../opensearch"

  for_each = local.opensearch

  application = var.args.application
  environment = var.environment
  name        = each.key
  vpc_name    = var.vpc_name

  config = each.value
}
