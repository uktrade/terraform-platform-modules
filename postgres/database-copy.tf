module "database-copy" {
  count = length(local.data_copy_tasks)
  source   = "../database-copy"

  application   = var.application
  environment   = var.environment
  database_name = var.name
  task          = local.data_copy_tasks[count.index]
}