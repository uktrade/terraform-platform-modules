terraform {
  required_version = "~> 1.8"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "sandbox-elasticache-redis"
  }
}
resource "aws_subnet" "primary" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-2a"
  tags = {
    Name = "sandbox-elasticache-redis-private-primary"
  }
}

resource "aws_security_group" "vpc-core-sg" {
  name        = "sandbox-elasticache-redis-base-sg"
  description = "Base security group for VPC"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "sandbox-elasticache-redis-base-sg"
  }
}
