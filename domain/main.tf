terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}

data "aws_route53_zone" "root-zone" {
  name = var.root-zone
}

resource "aws_route53_zone" "new-zone" {
  for_each = toset(var.zones)
  name     = "${each.key}.${data.aws_route53_zone.root-zone.name}"
  tags     = local.tags
}

resource "aws_route53_record" "ns-records" {
  for_each = toset(var.zones)
  name     = "${each.key}.${data.aws_route53_zone.root-zone.name}"
  ttl      = 172800
  type     = "NS"
  zone_id  = data.aws_route53_zone.root-zone.zone_id

  records = [
    aws_route53_zone.new-zone[each.key].name_servers[0],
    aws_route53_zone.new-zone[each.key].name_servers[1],
    aws_route53_zone.new-zone[each.key].name_servers[2],
    aws_route53_zone.new-zone[each.key].name_servers[3],
  ]
}
