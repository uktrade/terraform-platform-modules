locals {
    args = <<EOT
- aws_account: intranet
  name: dw-redis
  params:
    engine: '6.2'
    instance: cache.t4g.medium
    replicas: 0
  type: redis
  vpc: intranet-nonprod
- aws_account: intranet
  name: dw-postgres
  params:
    max_capacity: 8
    min_capacity: 0.5
    version: 14.4
  type: postgres
  vpc: intranet-nonprod
- aws_account: intranet
  name: dw-opensearch
  params:
    engine: '1.3'
    instance: t3.medium.search
    instances: 1
    master: false
    volume_size: 200
  type: opensearch
  vpc: intranet-nonprod
- aws_account: intranet
  name: dw-s3-bucket
  params:
    bucket_name: digital-workspace-v2-dev
    objects:
    - body: S3 Proxy is working.
      key: healthcheck.txt
  type: s3
  vpc: intranet-nonprod
- aws_account: intranet
  name: monitoring
  params:
    enable_ops_center: false
  type: monitoring
  vpc: intranet-nonprod
EOT
}

module "backing-services" {
    source = "../backing-services"

    vpc_name = "an-existing-vpc"

    args = tomap(yamldecode(local.args))
}
