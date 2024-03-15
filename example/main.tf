locals {
    args_yaml = <<EOT
services:
  - name: dw-redis
    params:
      engine: '6.2'
      instance: cache.t4g.medium
      replicas: 0
    type: redis
  - name: dw-postgres
    params:
      max_capacity: 8
      min_capacity: 0.5
      version: 14.4
    type: postgres
  - name: dw-opensearch
    params:
      engine: '1.3'
      instance: t3.medium.search
      instances: 1
      master: false
      volume_size: 200
    type: opensearch
  - name: dw-s3-bucket
    params:
      bucket_name: digital-workspace-v2-dev
      objects:
      - body: S3 Proxy is working.
        key: healthcheck.txt
    type: s3
  - name: monitoring
    params:
      enable_ops_center: false
    type: monitoring
  - name: dw-s3-bucket2
    params:
      bucket_name: digital-workspace-v2-dev_2
    type: s3    
  - name: dw-s3-bucket3
    params:
      bucket_name: digital-workspace-v2-dev_3
    type: s3    
  - name: dw-s3-bucket4
    params:
      bucket_name: digital-workspace-v2-dev_4
    type: s3    
EOT
  args = yamldecode(local.args_yaml)
}

module "backing-services" {
    source = "../backing-services"

    vpc_name = "an-existing-vpc"
    application = "example"
    environment = "staging"
    services = tomap(local.args)
}
