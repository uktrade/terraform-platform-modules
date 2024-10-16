module "database-dump" {
  count  = length(local.data_dump_tasks)
  source = "./database-dump"

  application   = var.application
  environment   = var.environment
  database_name = var.name
}


module "database-load" {
  count  = length(local.data_load_tasks)
  source = "./database-load"

  application   = var.application
  environment   = var.environment
  database_name = var.name
  task          = local.data_load_tasks[count.index]
}