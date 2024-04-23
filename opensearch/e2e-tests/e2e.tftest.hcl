variables {
  vpc_name    = "sandbox-opensearch"
  application = "opensearch-application"
  environment = "test"
  name        = "opensearch-name"
  config = {
    engine      = "2.5"
    instance    = "t3.small.search"
    instances   = 1
    volume_size = 80
    master      = false
  }
}

run "setup_tests" {
  module {
    source = "./e2e-tests/setup"
  }
}

run "opensearch_e2e_test" {
  command = apply

  assert {
    condition     = aws_opensearch_domain.this.domain_name == "test-opensearch-name"
    error_message = "Opensearch domain_name should be 'test-opensearch-name"
  }

  assert {
    condition     = aws_opensearch_domain.this.engine_version == "OpenSearch_2.5"
    error_message = "Opensearch engine_version should be 'OpenSearch_2.5'"
  }

  assert {
    condition     = aws_opensearch_domain.this.cluster_config[0].dedicated_master_type == ""
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
    condition     = aws_opensearch_domain.this.ebs_options[0].throughput == 0
    error_message = "Opensearch throughput should be null"
  }

  assert {
    condition     = aws_opensearch_domain.this.auto_tune_options[0].desired_state == "DISABLED"
    error_message = "Opensearch desired_state should be 'DISABLED'"
  }

  assert {
    condition     = aws_ssm_parameter.this-master-user.name == "/copilot/opensearch-application/test/secrets/OPENSEARCH_NAME_ENDPOINT"
    error_message = "Parameter store parameter name should be '/copilot/opensearch-application/test/secrets/OPENSEARCH_NAME_ENDPOINT'"
  }

  assert {
    condition     = aws_ssm_parameter.this-master-user.description == "opensearch_password"
    error_message = "Opensearch description should be 'opensearch_password'"
  }
}
