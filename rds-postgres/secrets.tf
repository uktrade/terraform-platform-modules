# data "aws_secretsmanager_secret" "secret" {
#   arn = module.this.db_instance_master_user_secret_arn
# }

# data "aws_secretsmanager_secret_version" "current" {
#   secret_id = data.aws_secretsmanager_secret.secret.id
# }

# resource "aws_ssm_parameter" "connection-string" {
#   name  = "/copilot/${var.application}/${var.environment}/secrets/${upper(replace("${var.name}-rds-postgres", "-", "_"))}"
#   type  = "SecureString"
#   value = jsonencode({
#     "username"=jsondecode(nonsensitive(data.aws_secretsmanager_secret_version.current.secret_string)).username,
#     "password"=urlencode(jsondecode(nonsensitive(data.aws_secretsmanager_secret_version.current.secret_string)).password),
#     "engine"="postgres",
#     "port"=module.this.db_instance_port,
#     "dbname"=module.this.db_instance_name,
#     "host"=split(":", module.this.db_instance_endpoint)[0]
#   })
#   tags = local.tags
# }