mock_provider "aws" {}

variables {
  config = {
    id                        = "pcx-12345678"
    accepter_account_id       = "123456789"
    requester_subnet          = "10.10.10.0/24"
    accepter_vpc              = "vpc-22222222"
    requester_vpc_name        = "vpc-requester"
    requester_vpc             = "vpc-11111111"
    vpc_peering_connection_id = "pcx-12345"
  }
}

run "accept_connection" {
  command = plan

  assert {
    # Ensure the VPC peering connection exists
    condition     = aws_vpc_peering_connection_accepter.this.vpc_peering_connection_id == "pcx-12345"
    error_message = "VPC peering connection was not created."
  }
}
