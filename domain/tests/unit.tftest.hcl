variables {
  zones     = ["a", "b", "c"]
  root-zone = "test-zone"
}

mock_provider "aws" {
}

run "aws_route53_zone_unit_test" {
  command = plan

  assert {
    condition     = [for el in aws_route53_zone.new-zone : true if el.name == "a.test-zone"][0] == false
    error_message = "Invalid name for aws_route53_zone.new-zone.a, should be a.test-zone"
  }

  assert {
    condition     = [for el in aws_route53_zone.new-zone : true if el.name == "b.test-zone"][0] == true
    error_message = "Invalid name for aws_route53_zone.new-zone.b, should be b.test-zone"
  }

  assert {
    condition     = [for el in aws_route53_zone.new-zone : true if el.name == "c.test-zone"][0] == true
    error_message = "Invalid name for aws_route53_zone.new-zone.c, should be c.test-zone"
  }

  assert {
    condition     = [for el in aws_route53_zone.new-zone : true if el.tags["managed-by"] == "DBT Platform - Terraform"][0] == true
    error_message = "Invalid value for aws_route53_zone.new-zone tags parameter."
  }
}

run "aws_route53_record_unit_test" {
  command = plan

  assert {
    condition     = [for el in aws_route53_record.ns-records : true if el.name == "a.test-zone"][0] == true
    error_message = "Invalid name for aws_route53_record.ns-records.a, should be a.test-zone"
  }

  assert {
    condition     = [for el in aws_route53_record.ns-records : true if el.name == "b.test-zone"][0] == true
    error_message = "Invalid name for aws_route53_record.ns-records.b, should be b.test-zone"
  }

  assert {
    condition     = [for el in aws_route53_record.ns-records : true if el.name == "c.test-zone"][0] == true
    error_message = "Invalid name for aws_route53_record.ns-records.c, should be c.test-zone"
  }

  assert {
    condition     = [for el in aws_route53_record.ns-records : true if el.ttl == 172800][0] == true
    error_message = "Invalid value for aws_route53_record.ns-records ttl parameter, should be 172800"
  }

  assert {
    condition     = [for el in aws_route53_record.ns-records : true if el.type == "NS"][0] == true
    error_message = "Invalid value for aws_route53_record.ns-records type parameter, should be NS"
  }
}
