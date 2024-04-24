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

run "aws_vpc_unit_test" {
  command = plan

  ### Test aws_vpc resource ###
  assert {
    condition     = aws_vpc.vpc.enable_dns_hostnames == true
    error_message = "Invalid VPC settings"
  }

  assert {
    condition     = aws_vpc.vpc.enable_dns_support == true
    error_message = "Invalid VPC settings"
  }

  assert {
    condition     = aws_vpc.vpc.tags.Name == "vpc-test-name"
    error_message = "Invalid VPC tags"
  }

  assert {
    condition     = aws_vpc.vpc.tags.managed-by == "DBT Platform - Terraform"
    error_message = "Invalid VPC tags"
  }

  ### Test aws_vpc_endpoint resource ###
  assert {
    condition     = aws_vpc_endpoint.rds-vpc-endpoint.service_name == "com.amazonaws.eu-west-2.secretsmanager"
    error_message = "Invalid VPC endpoint service name"
  }

  assert {
    condition     = aws_vpc_endpoint.rds-vpc-endpoint.private_dns_enabled == true
    error_message = "Invalid VPC endpoint private dns status"
  }
}

run "aws_security_group_unit_test" {
  command = plan

  ### Test aws_security_group resource ###
  assert {
    condition     = aws_security_group.vpc-core-sg.revoke_rules_on_delete == false
    error_message = "Invalid security group settings"
  }

  ### Test aws_security_group_rule resource ###
  assert {
    condition     = aws_security_group_rule.rds-db-egress-db-to-lambda.protocol == "tcp"
    error_message = "Invalid security group rule protocol"
  }

  assert {
    condition     = aws_security_group_rule.rds-db-egress-db-to-lambda.type == "egress"
    error_message = "Invalid security group rule type"
  }

  assert {
    condition     = aws_security_group_rule.rds-db-egress-https.protocol == "tcp"
    error_message = "Invalid security group rule protocol"
  }

  assert {
    condition     = aws_security_group_rule.rds-db-egress-https.type == "egress"
    error_message = "Invalid security group rule type"
  }

  assert {
    condition     = aws_security_group_rule.rds-db-egress-sm-to-lambda.protocol == "tcp"
    error_message = "Invalid security group rule protocol"
  }

  assert {
    condition     = aws_security_group_rule.rds-db-egress-sm-to-lambda.type == "egress"
    error_message = "Invalid security group rule type"
  }

  assert {
    condition     = aws_security_group_rule.rds-db-ingress-fargate.protocol == "tcp"
    error_message = "Invalid security group rule protocol"
  }

  assert {
    condition     = aws_security_group_rule.rds-db-ingress-fargate.type == "ingress"
    error_message = "Invalid security group rule type"
  }

  assert {
    condition     = aws_security_group_rule.rds-db-ingress-lambda-to-db.protocol == "tcp"
    error_message = "Invalid security group rule protocol"
  }

  assert {
    condition     = aws_security_group_rule.rds-db-ingress-lambda-to-db.type == "ingress"
    error_message = "Invalid security group rule type"
  }

  assert {
    condition     = aws_security_group_rule.rds-db-ingress-lambda-to-sm.protocol == "tcp"
    error_message = "Invalid security group rule protocol"
  }

  assert {
    condition     = aws_security_group_rule.rds-db-ingress-lambda-to-sm.type == "ingress"
    error_message = "Invalid security group rule type"
  }
}

run "aws_subnet_unit_test" {
  command = plan

  ### Test aws_subnet private resource ###
  assert {
    condition     = aws_subnet.private["a"].availability_zone == "eu-west-2a"
    error_message = "Invalid private subnet config"
  }

  assert {
    condition     = aws_subnet.private["a"].cidr_block == "10.0.1.0/24"
    error_message = "Invalid private subnet config"
  }

  assert {
    condition     = aws_subnet.private["a"].map_public_ip_on_launch == false
    error_message = "Invalid private subnet config"
  }

  assert {
    condition     = aws_subnet.private["a"].tags.subnet_type == "private"
    error_message = "Invalid private subnet config"
  }

  ### Test aws_subnet public resource ###
  assert {
    condition     = aws_subnet.public["a"].availability_zone == "eu-west-2a"
    error_message = "Invalid public subnet config"
  }

  assert {
    condition     = aws_subnet.public["a"].cidr_block == "10.0.128.0/24"
    error_message = "Invalid public subnet config"
  }

  assert {
    condition     = aws_subnet.public["a"].tags.subnet_type == "public"
    error_message = "Invalid public subnet config"
  }

  ### Test aws_subnet.private-subnets resource ###
  assert {
    condition     = [for el in data.aws_subnets.private-subnets.filter : true if[for el2 in el.values : true if el2 == "vpc-test-name-private-*"][0] == true][0] == true
    error_message = "Invalid aws private subnets filter"
  }
}

run "aws_default_network_acl_unit_test" {
  command = plan

  ### Test aws_default_network_acl resource ###
  assert {
    condition     = [for el in aws_default_network_acl.default-acl.egress : true if el.action == "allow"][0] == true
    error_message = "Invalid default network ACL"
  }

  assert {
    condition     = [for el in aws_default_network_acl.default-acl.ingress : true if el.action == "allow"][0] == true
    error_message = "Invalid default network ACL"
  }
}
