run "test_create_opensearch" {
  command = apply

  variables {
    application = "my_app"
    environment = "my_env"
    space       = "sandbox-ant"

    config = {
      name   = "my-opensearch"
      engine = "2.5"
      plan   = "tiny"
    }
  }

  assert {
    condition     = aws_opensearch_domain.this.domain_name == "my-opensearch-engine"
    error_message = "Opensearch domain_name should be 'my-opensearch-engine'"
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
    condition     = aws_opensearch_domain.this.auto_tune_options[0].desired_state == "DISABLED"
    error_message = "Opensearch desired_state should be 'DISABLED'"
  }

  assert {
    condition     = aws_ssm_parameter.this-master-user.name == "/copilot/my-opensearch/my_env/secrets/MY_OPENSEARCH_OPENSEARCH"
    error_message = "Parameter store parameter name should be '/copilot/my-opensearch/my_env/secrets/MY_OPENSEARCH_OPENSEARCH'"
  }

  assert {
    condition     = aws_ssm_parameter.this-master-user.description == "opensearch_password"
    error_message = "Opensearch description should be 'opensearch_password'"
  }
}

run "test_create_opensearch_override_volume_size" {
  command = plan

  variables {
    application = "my_app"
    environment = "my_env"
    space       = "sandbox-ant"

    config = {
      name        = "my-opensearch"
      engine      = "2.5"
      plan        = "tiny"
      volume_size = 500
    }
  }

  assert {
    condition     = aws_opensearch_domain.this.ebs_options[0].volume_size == 500
    error_message = "Opensearch volume_size should be 500"
  }
}

run "test_create_opensearch_x_large_ha" {
  command = plan

  variables {
    application = "my_app"
    environment = "my_env"
    space       = "sandbox-ant"

    config = {
      name   = "my-opensearch"
      engine = "2.5"
      plan   = "x-large-ha"
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
    condition     = aws_ssm_parameter.this-master-user.name == "/copilot/my-opensearch/my_env/secrets/MY_OPENSEARCH_OPENSEARCH"
    error_message = "Parameter store parameter name should be '/copilot/my-opensearch/my_env/secrets/MY_OPENSEARCH_OPENSEARCH'"
  }

  assert {
    condition     = aws_ssm_parameter.this-master-user.description == "opensearch_password"
    error_message = "Opensearch description should be 'opensearch_password'"
  }
}
