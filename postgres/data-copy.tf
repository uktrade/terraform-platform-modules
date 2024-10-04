module "data-copy" {
  count = length(local.data_copy_tasks)
  source   = "../data-copy"

  application   = var.application
  environment   = var.environment
  database_name = var.name
  task          = local.data_copy_tasks[count.index]
}