provider "aws" {
  profile = "sandbox"
  shared_config_files = ["~/.aws/config"]
  region = "eu-west-2"
}

variables {
  args = {
    application = "opensearch-test-jamesm"
    environment = "sandbox"
    space = "sandbox-jamesm"
    name = "test"
  }
  ebs_enabled              = true
  ebs_volume_size          = 45
  engine_version           = "2.3"
  instance_count           = 1
  instance_type            = "t3.small.search"
  security_options_enabled = true
  throughput               = 250
  volume_type              = "gp3"
  allowed_instance_types   = ["m6.large.search", "t3.small.search"]
}

run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

run "e2e_test" {
  command = plan

  ## Test generated password
  assert {
    condition = random_password.password.length >= 32
    error_message = "Create a password at least 32 characters in length"
  }

  assert {
    condition = [ for config in aws_opensearch_domain.this.cluster_config : true if contains(var.allowed_instance_types, config.instance_type)][0] == true
    error_message = "Invalid instance type"
  }

  assert {
    condition = length(aws_opensearch_domain.this.domain_name) <= 28
    error_message = "Name exceeds max character length of 28"
  }

  assert {
    condition = [ for secopts in aws_opensearch_domain.this.advanced_security_options : true if secopts.enabled ][0] == true
    error_message = "Advanced Security Options should be enabled"
  }

  assert {
    condition = [for ebs in aws_opensearch_domain.this.ebs_options : true if ebs.ebs_enabled == true][0] == true
    error_message = "EBS must be enabled"
  }
  assert {
    condition = [for ebs in aws_opensearch_domain.this.ebs_options : true if can(ebs.volume_size >= 45) ][0] == true
    error_message = "Volume size is too small, minimum is 45"
  }
  assert {
    condition = [for ebs in aws_opensearch_domain.this.ebs_options : true if can(ebs.throughput <= 125) ][0] == true
    error_message = "Disk throughput is too low, minimum is 125"
  }
  assert {
    condition = [for ebs in aws_opensearch_domain.this.ebs_options : true if ebs.volume_type == "gp3" ][0] == true
    error_message = "Volume type must be gp3"
  }
}