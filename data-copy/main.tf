module "database-dump" {
  count = local.is_data_dump ? 1 : 0
  source   = "../database-dump"

  application   = var.application
  environment   = var.environment
  database_name = var.database_name
}

module "database-restore" {
  count = local.is_data_dump ? 0 : 1
  depends_on = [module.database-dump[0]]
  source   = "../database-restore"

  application   = var.application
  environment   = var.environment
  database_name = var.database_name
  data_dump_bucket_arn = module.database-dump[0].data_dump_bucket_arn
  data_dump_kms_key_arn = module.database-dump[0].data_dump_kms_key_arn
}