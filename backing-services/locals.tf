locals {
    postgres = { for k, v in var.args : k => v if v.type == "postgres" }
    s3 = { for k, v in var.args : k => v if v.type == "s3" }
    redis = { for k, v in var.args : k => v if v.type == "redis" }
    opensearch = { for k, v in var.args : k => v if v.type == "opensearch" }
}