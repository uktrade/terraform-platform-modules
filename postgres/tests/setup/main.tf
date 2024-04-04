terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "sandbox-postgres"
  }
}
resource "aws_subnet" "primary" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-2a"
  tags = {
    Name = "sandbox-postgres-private-primary"
  }
}

resource "aws_security_group" "vpc-core-sg" {
  name        = "sandbox-postgres-base-sg"
  description = "Base security group for VPC"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "sandbox-postgres-base-sg"
  }
}