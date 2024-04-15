
variables {
  arg_name = "vpc-test-name"
  arg_config = {
    "cidr"         = "10.0",
    "nat_gateways" = ["a"],
    "az_map" = {
      "private" = { "a" = "1", "b" = "2" },
      "public"  = { "a" = "128", "b" = "129" }
    }
  }
}

run "e2e_tests" {
  command = apply

  ### Test aws_vpc resource ###
  assert {
    condition     = aws_vpc.vpc.enable_dns_hostnames == true
    error_message = "Invalid VPC settings"
  }

  assert {
    condition     = aws_vpc.vpc.tags.Name == "vpc-test-name"
    error_message = "Invalid VPC tags"
  }

  assert {
    condition     = aws_vpc.vpc.tags.managed-by == "Terraform"
    error_message = "Invalid VPC tags"
  }

  ### Test aws_security_group resource ###
  assert {
    condition     = startswith(aws_security_group.vpc-core-sg.arn, "arn:aws:ec2:eu-west-2:852676506468:security-group/sg-") == true
    error_message = "Invalid security group settings"
  }

  ### Test aws_vpc_endpoint resource ###
  assert {
    condition     = aws_vpc_endpoint.rds-vpc-endpoint.vpc_endpoint_type == "Interface"
    error_message = "Invalid VPC endpoint type"
  }

  assert {
    condition     = aws_vpc_endpoint.rds-vpc-endpoint.state == "available"
    error_message = "Invalid VPC endpoint state"
  }

  assert {
    condition     = aws_vpc_endpoint.rds-vpc-endpoint.dns_options[0].dns_record_ip_type == "ipv4"
    error_message = "Invalid VPC endpoint dns record ip type"
  }
}