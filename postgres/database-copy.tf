module "database-dump" {
  count = length(local.data_dump_tasks)
  source   = "./database-dump"

  application   = var.application
  environment   = var.environment
  database_name = var.name
}


module "database-restore" {
  count = length(local.data_restore_tasks)
  source   = "./database-restore"

  application   = var.application
  environment   = var.environment
  database_name = var.name
  task          = local.data_restore_tasks[count.index]
}