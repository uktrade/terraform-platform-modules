override_data {
  target = data.aws_vpc.vpc
  values = {
    id         = "vpc-00112233aabbccdef"
    cidr_block = "10.0.0.0/16"
  }
}

override_data {
  target = data.aws_subnets.private-subnets
  values = {
    ids = ["subnet-000111222aaabbb01", "subnet-000111222aaabbb02", "subnet-000111222aaabbb03"]
  }
}

run "test_create_opensearch" {
  command = plan

  variables {
    application = "my_app"
    environment = "my_env"
    name        = "my_name"
    vpc_name    = "terraform-tests-vpc"

    config = {
      engine      = "2.5"
      instance    = "t3.small.search"
      instances   = 1
      volume_size = 80
      master      = false
    }
  }

  assert {
    condition     = aws_opensearch_domain.this.domain_name == "my-name-my-env"
    error_message = "Opensearch domain_name should be 'my-name-my-env'"
  }

  assert {
    condition     = aws_opensearch_domain.this.engine_version == "OpenSearch_2.5"
    error_message = "Opensearch engine_version should be 'OpenSearch_2.5'"
  }

  assert {
    condition     = aws_opensearch_domain.this.cluster_config[0].dedicated_master_type == null
    error_message = "Opensearch dedicated_master_type should be null"
  }

  assert {
    condition     = aws_opensearch_domain.this.cluster_config[0].dedicated_master_enabled == false
    error_message = "Opensearch dedicated_master_enabled should be false"
  }

  assert {
    condition     = aws_opensearch_domain.this.cluster_config[0].instance_type == "t3.small.search"
    error_message = "Opensearch instance_type should be 't3.small.search'"
  }

  assert {
    condition     = aws_opensearch_domain.this.cluster_config[0].instance_count == 1
    error_message = "Opensearch instance_count should be 1"
  }

  assert {
    condition     = aws_opensearch_domain.this.ebs_options[0].volume_size == 80
    error_message = "Opensearch volume_size should be 80"
  }

  assert {
    condition     = aws_opensearch_domain.this.ebs_options[0].volume_type == "gp2"
    error_message = "Opensearch volume_type should be 'gp2'"
  }

  assert {
    condition     = aws_opensearch_domain.this.ebs_options[0].throughput == 250
    error_message = "Opensearch throughput should be null"
  }

  assert {
    condition     = aws_opensearch_domain.this.auto_tune_options[0].desired_state == "DISABLED"
    error_message = "Opensearch desired_state should be 'DISABLED'"
  }

  assert {
    condition     = aws_opensearch_domain.this.tags.application == "my_app"
    error_message = "application tag was not as expected"
  }

  assert {
    condition     = aws_opensearch_domain.this.tags.environment == "my_env"
    error_message = "environment tag was not as expected"
  }

  assert {
    condition     = aws_opensearch_domain.this.tags.managed-by == "DBT Platform - Terraform"
    error_message = "managed-by tag was not as expected"
  }

  assert {
    condition     = aws_opensearch_domain.this.tags.copilot-application == "my_app"
    error_message = "copilot-application tag was not as expected"
  }

  assert {
    condition     = aws_opensearch_domain.this.tags.copilot-environment == "my_env"
    error_message = "copilot-environment tag was not as expected"
  }

  assert {
    condition     = aws_ssm_parameter.this-master-user.name == "/copilot/my-name/my_env/secrets/OPENSEARCH_PASSWORD"
    error_message = "Parameter store parameter name should be '/copilot/my-name/my_env/secrets/OPENSEARCH_PASSWORD'"
  }

  assert {
    condition     = aws_ssm_parameter.this-master-user.description == "opensearch_password"
    error_message = "Opensearch description should be 'opensearch_password'"
  }

  assert {
    condition     = aws_cloudwatch_log_group.opensearch_log_group_index_slow_logs.retention_in_days == 7
    error_message = "index_slow_logs retention in days should be 7"
  }

  assert {
    condition     = aws_cloudwatch_log_group.opensearch_log_group_search_slow_logs.retention_in_days == 7
    error_message = "search_slow_logs retention in days should be 7"
  }

  assert {
    condition     = aws_cloudwatch_log_group.opensearch_log_group_es_application_logs.retention_in_days == 7
    error_message = "es_application_logs retention in days should be 7"
  }

  assert {
    condition     = aws_cloudwatch_log_group.opensearch_log_group_audit_logs.retention_in_days == 7
    error_message = "audit_logs retention in days should be 7"
  }
}

run "test_create_opensearch_x_large_ha" {
  command = plan

  variables {
    application = "my_app"
    environment = "my_env"
    name        = "my_name"
    vpc_name    = "terraform-tests-vpc"

    config = {
      name        = "my_name"
      engine      = "2.5"
      instance    = "m6g.2xlarge.search"
      instances   = 2
      volume_size = 1500
      master      = false
    }
  }

  assert {
    condition     = aws_opensearch_domain.this.cluster_config[0].dedicated_master_type == null
    error_message = "Opensearch dedicated_master_type should be null"
  }

  assert {
    condition     = aws_opensearch_domain.this.cluster_config[0].dedicated_master_enabled == false
    error_message = "Opensearch dedicated_master_enabled should be false"
  }

  assert {
    condition     = aws_opensearch_domain.this.cluster_config[0].instance_type == "m6g.2xlarge.search"
    error_message = "Opensearch instance_type should be 'm6g.2xlarge.search'"
  }

  assert {
    condition     = aws_opensearch_domain.this.cluster_config[0].instance_count == 2
    error_message = "Opensearch instance_count should be 2"
  }

  assert {
    condition     = aws_opensearch_domain.this.ebs_options[0].volume_size == 1500
    error_message = "Opensearch volume_size should be 1500"
  }

  assert {
    condition     = aws_opensearch_domain.this.auto_tune_options[0].desired_state == "ENABLED"
    error_message = "Opensearch desired_state should be 'ENABLED'"
  }

  assert {
    condition     = aws_ssm_parameter.this-master-user.name == "/copilot/my-name/my_env/secrets/OPENSEARCH_PASSWORD"
    error_message = "Parameter store parameter name should be '/copilot/my-name/my_env/secrets/OPENSEARCH_PASSWORD'"
  }

  assert {
    condition     = aws_ssm_parameter.this-master-user.description == "opensearch_password"
    error_message = "Opensearch description should be 'opensearch_password'"
  }
}

run "test_overrides" {
  command = plan

  variables {
    application = "my_app"
    environment = "my_env"
    name        = "my_name"
    vpc_name    = "terraform-tests-vpc"

    config = {
      name                              = "my_name"
      engine                            = "2.5"
      instance                          = "t3.small.search"
      instances                         = 1
      volume_size                       = 80
      master                            = false
      ebs_volume_type                   = "gp3"
      ebs_throughput                    = 500
      index_slow_log_retention_in_days  = 3
      search_slow_log_retention_in_days = 14
      es_app_log_retention_in_days      = 30
      audit_log_retention_in_days       = 1096
    }
  }

  assert {
    condition     = aws_opensearch_domain.this.ebs_options[0].volume_type == "gp3"
    error_message = "Opensearch volume_type should be 'gp3'"
  }

  assert {
    condition     = aws_opensearch_domain.this.ebs_options[0].throughput == 500
    error_message = "Opensearch throughput should be 500"
  }

  assert {
    condition     = aws_cloudwatch_log_group.opensearch_log_group_index_slow_logs.retention_in_days == 3
    error_message = "index_slow_logs retention in days should be 3"
  }

  assert {
    condition     = aws_cloudwatch_log_group.opensearch_log_group_search_slow_logs.retention_in_days == 14
    error_message = "search_slow_logs retention in days should be 14"
  }

  assert {
    condition     = aws_cloudwatch_log_group.opensearch_log_group_es_application_logs.retention_in_days == 30
    error_message = "es_application_logs retention in days should be 30"
  }

  assert {
    condition     = aws_cloudwatch_log_group.opensearch_log_group_audit_logs.retention_in_days == 1096
    error_message = "audit_logs retention in days should be 1096"
  }
}

run "test_volume_type_validation" {
  command = plan

  variables {
    application = "my_app"
    environment = "my_env"
    name        = "my_name"
    vpc_name    = "terraform-tests-vpc"

    config = {
      name                              = "my_name"
      engine                            = "2.5"
      instance                          = "t3.small.search"
      instances                         = 1
      volume_size                       = 80
      master                            = false
      ebs_volume_type                   = "banana"
      index_slow_log_retention_in_days  = 9
      search_slow_log_retention_in_days = 10
      es_app_log_retention_in_days      = 13
      audit_log_retention_in_days       = 37
    }
  }

  expect_failures = [
    var.config.ebs_volume_type,
    var.config.index_slow_log_retention_in_days,
    var.config.search_slow_log_retention_in_days,
    var.config.es_app_log_retention_in_days,
    var.config.audit_log_retention_in_days,
  ]
}
