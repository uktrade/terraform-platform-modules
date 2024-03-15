locals {
    postgres = { for k, v in var.services.services : k => v if v.type == "postgres" }
    s3 = { for k, v in var.services.services : k => v if v.type == "s3" }
    redis = { for k, v in var.services.services : k => v if v.type == "redis" }
    opensearch = { for k, v in var.services.services : k => v if v.type == "opensearch" }
    monitoring = { for k, v in var.services.services : k => v if v.type == "monitoring" }
}
