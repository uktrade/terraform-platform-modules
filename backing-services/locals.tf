locals {
    postgres = { for k, v in var.args.services : k => v if v.type == "postgres" }
    s3 = { for k, v in var.args.services : k => v if v.type == "s3" }
    redis = { for k, v in var.args.services : k => v if v.type == "redis" }
    opensearch = { for k, v in var.args.services : k => v if v.type == "opensearch" }
    monitoring = { for k, v in var.args.services : k => v if v.type == "monitoring" }
}

output "postgres" {
    value = local.postgres
}

output "redis" {
    value = local.redis
}

output "s3" {
    value = local.s3
}

output "opensearch" {
    value = local.opensearch
}

output "monitoring" {
    value = local.monitoring
}