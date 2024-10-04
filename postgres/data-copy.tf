module "data-copy" {
  for_each = local.data_copy_tasks
  source   = "../data-copy"

  application   = var.application
  environment   = var.environment
  database_name = var.name
  task          = each.value
}