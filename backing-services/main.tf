module "rds-postgres" {
    source =  "../rds-postgres"

    for_each = local.postgres
    vpc_name = var.vpc_name
}

module "redis" {
    source   = "../elasticache-redis"

    for_each = local.redis
    vpc_name = var.vpc_name    
}

module "s3" {
    source = "s3"

    for_each = local.s3
    vpc_name = var.vpc_name    
}

module "opensearch" {
    source   = "../opensearch"

    for_each = local.openserch
    vpc_name = var.vpc_name    

    # TODO: some of these aren't needed, the required vars should be migrated to args
    engine_version           = "2.3"
    security_options_enabled = true
    volume_type              = "gp3"
    throughput               = 250
    ebs_enabled              = true
    ebs_volume_size          = 45
    instance_type            = "m6g.large.search"
    instance_count           = 1
    dedicated_master_enabled = false
    dedicated_master_count   = 1
    dedicated_master_type    = "m6g.large.search"
    zone_awareness_enabled   = false
}
