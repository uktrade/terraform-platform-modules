variables {
  vpc_name    = "sandbox-elasticache-redis"
  application = "redis-test-application"
  environment = "redis-test-environment"
  name        = "redis-test-name"
  config = {
    "engine" = "6.2",
    "plan"   = "small",
  }
}

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

run "aws_elasticache_replication_group_unit_test" {
  command = plan

  ### Test aws_elasticache_replication_group resource ###
  assert {
    condition     = aws_elasticache_replication_group.redis.replication_group_id == "redis-test-name-redis-test-environment"
    error_message = "Invalid config for aws_elasticache_replication_group replication_group_id"
  }

  assert {
    condition     = aws_elasticache_replication_group.redis.subnet_group_name == "redis-test-name-redis-test-environment-cache-subnet"
    error_message = "Invalid config for aws_elasticache_replication_group subnet_group_name"
  }

  assert {
    condition     = aws_elasticache_replication_group.redis.engine == "redis"
    error_message = "Invalid config for aws_elasticache_replication_group engine"
  }

  assert {
    condition     = aws_elasticache_replication_group.redis.engine_version == "6.2"
    error_message = "Invalid config for aws_elasticache_replication_group engine_version"
  }

  assert {
    condition     = aws_elasticache_replication_group.redis.num_node_groups == 1
    error_message = "Invalid config for aws_elasticache_replication_group num_node_groups"
  }

  assert {
    condition     = aws_elasticache_replication_group.redis.replicas_per_node_group == 1
    error_message = "Invalid config for aws_elasticache_replication_group replicas_per_node_group"
  }

  assert {
    condition     = aws_elasticache_replication_group.redis.transit_encryption_enabled == true
    error_message = "Invalid config for aws_elasticache_replication_group transit_encryption_enabled"
  }

  assert {
    condition     = aws_elasticache_replication_group.redis.at_rest_encryption_enabled == true
    error_message = "Invalid config for aws_elasticache_replication_group at_rest_encryption_enabled"
  }

  assert {
    condition     = aws_elasticache_replication_group.redis.apply_immediately == false
    error_message = "Invalid config for aws_elasticache_replication_group apply_immediately"
  }

  assert {
    condition     = aws_elasticache_replication_group.redis.automatic_failover_enabled == false
    error_message = "Invalid config for aws_elasticache_replication_group automatic_failover_enabled"
  }

  assert {
    condition     = aws_elasticache_replication_group.redis.multi_az_enabled == false
    error_message = "Invalid config for aws_elasticache_replication_group multi_az_enabled"
  }

  assert {
    condition     = aws_elasticache_replication_group.redis.auth_token_update_strategy == "ROTATE"
    error_message = "Invalid config for aws_elasticache_replication_group auth_token_update_strategy"
  }

  assert {
    condition     = [for el in aws_elasticache_replication_group.redis.log_delivery_configuration : el.destination if el.log_type == "engine-log"][0] == "/aws/elasticache/redis-test-name/redis-test-environment/redis-test-nameRedis/engine"
    error_message = "Invalid config for aws_elasticache_replication_group log_delivery_configuration"
  }

  assert {
    condition     = [for el in aws_elasticache_replication_group.redis.log_delivery_configuration : el.destination if el.log_type == "slow-log"][0] == "/aws/elasticache/redis-test-name/redis-test-environment/redis-test-nameRedis/slow"
    error_message = "Invalid config for aws_elasticache_replication_group log_delivery_configuration"
  }
}

run "aws_elasticache_replication_group_unit_test2" {
  command = plan

  variables {
    config = {
      "engine"                     = "7.1",
      "plan"                       = "small",
      "instance"                   = "test-instance",
      "replicas"                   = 2,
      "apply_immediately"          = true,
      "automatic_failover_enabled" = true,
      "multi_az_enabled"           = true,
    }
  }

  ### Test aws_elasticache_replication_group resource ###
  assert {
    condition     = aws_elasticache_replication_group.redis.engine == "redis"
    error_message = "Invalid config for aws_elasticache_replication_group engine"
  }

  assert {
    condition     = aws_elasticache_replication_group.redis.engine_version == "7.1"
    error_message = "Invalid config for aws_elasticache_replication_group engine_version"
  }

  assert {
    condition     = aws_elasticache_replication_group.redis.num_node_groups == 1
    error_message = "Invalid config for aws_elasticache_replication_group num_node_groups"
  }

  assert {
    condition     = aws_elasticache_replication_group.redis.replicas_per_node_group == 2
    error_message = "Invalid config for aws_elasticache_replication_group replicas_per_node_group"
  }

  assert {
    condition     = aws_elasticache_replication_group.redis.transit_encryption_enabled == true
    error_message = "Invalid config for aws_elasticache_replication_group transit_encryption_enabled"
  }

  assert {
    condition     = aws_elasticache_replication_group.redis.at_rest_encryption_enabled == true
    error_message = "Invalid config for aws_elasticache_replication_group at_rest_encryption_enabled"
  }

  assert {
    condition     = aws_elasticache_replication_group.redis.apply_immediately == true
    error_message = "Invalid config for aws_elasticache_replication_group apply_immediately"
  }

  assert {
    condition     = aws_elasticache_replication_group.redis.automatic_failover_enabled == true
    error_message = "Invalid config for aws_elasticache_replication_group automatic_failover_enabled"
  }

  assert {
    condition     = aws_elasticache_replication_group.redis.multi_az_enabled == true
    error_message = "Invalid config for aws_elasticache_replication_group multi_az_enabled"
  }
}

run "aws_security_group_unit_test" {
  command = plan

  ### Test aws_security_group resource ###
  assert {
    condition     = aws_security_group.redis.name == "redis-test-name-redis-test-environment-redis-security-group"
    error_message = "Invalid config for aws_security_group name"
  }

  assert {
    condition     = aws_security_group.redis.revoke_rules_on_delete == false
    error_message = "Invalid config for aws_security_group revoke_rules_on_delete"
  }
}

run "aws_ssm_parameter_unit_test" {
  command = plan

  ### Test aws_ssm_parameter resource ###
  assert {
    condition     = aws_ssm_parameter.endpoint.name == "/copilot/redis-test-application/redis-test-environment/secrets/REDIS_TEST_NAME"
    error_message = "Invalid config for aws_ssm_parameter name"
  }

  assert {
    condition     = aws_ssm_parameter.endpoint.type == "SecureString"
    error_message = "Invalid config for aws_ssm_parameter type"
  }
}

run "aws_cloudwatch_log_group_unit_test" {
  command = plan

  ### Test aws_cloudwatch_log_group slow resource ###
  assert {
    condition     = aws_cloudwatch_log_group.redis-slow-log-group.name == "/aws/elasticache/redis-test-name/redis-test-environment/redis-test-nameRedis/slow"
    error_message = "Invalid config for aws_cloudwatch_log_group name"
  }

  assert {
    condition     = aws_cloudwatch_log_group.redis-slow-log-group.retention_in_days == 7
    error_message = "Invalid config for aws_cloudwatch_log_group retention_in_days"
  }

  assert {
    condition     = aws_cloudwatch_log_group.redis-slow-log-group.skip_destroy == false
    error_message = "Invalid config for aws_cloudwatch_log_group skip_destroy"
  }

  ### Test aws_cloudwatch_log_group engine resource ###
  assert {
    condition     = aws_cloudwatch_log_group.redis-engine-log-group.name == "/aws/elasticache/redis-test-name/redis-test-environment/redis-test-nameRedis/engine"
    error_message = "Invalid config for aws_cloudwatch_log_group name"
  }

  assert {
    condition     = aws_cloudwatch_log_group.redis-engine-log-group.retention_in_days == 7
    error_message = "Invalid config for aws_cloudwatch_log_group retention_in_days"
  }

  assert {
    condition     = aws_cloudwatch_log_group.redis-engine-log-group.skip_destroy == false
    error_message = "Invalid config for aws_cloudwatch_log_group skip_destroy"
  }
}

run "aws_cloudwatch_log_subscription_filter_unit_test" {
  command = plan

  ### Test aws_cloudwatch_log_subscription_filter engine resource ###
  assert {
    condition     = aws_cloudwatch_log_subscription_filter.redis-subscription-filter-engine.name == "/aws/elasticache/redis-test-name/redis-test-environment/engine"
    error_message = "Invalid config for aws_cloudwatch_log_subscription_filter name"
  }

  assert {
    condition     = aws_cloudwatch_log_subscription_filter.redis-subscription-filter-engine.destination_arn == "arn:aws:logs:eu-west-2:812359060647:destination:cwl_log_destination"
    error_message = "Invalid config for aws_cloudwatch_log_subscription_filter destination_arn"
  }

  assert {
    condition     = aws_cloudwatch_log_subscription_filter.redis-subscription-filter-engine.distribution == "ByLogStream"
    error_message = "Invalid config for aws_cloudwatch_log_subscription_filter distribution"
  }

  assert {
    condition     = aws_cloudwatch_log_subscription_filter.redis-subscription-filter-engine.role_arn == "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CWLtoSubscriptionFilterRole"
    error_message = "Invalid config for aws_cloudwatch_log_subscription_filter role_arn"
  }

  ### Test aws_cloudwatch_log_subscription_filter slow resource ###
  assert {
    condition     = aws_cloudwatch_log_subscription_filter.redis-subscription-filter-slow.name == "/aws/elasticache/redis-test-name/redis-test-environment/slow"
    error_message = "Invalid config for aws_cloudwatch_log_subscription_filter name"
  }

  assert {
    condition     = aws_cloudwatch_log_subscription_filter.redis-subscription-filter-slow.destination_arn == "arn:aws:logs:eu-west-2:812359060647:destination:cwl_log_destination"
    error_message = "Invalid config for aws_cloudwatch_log_subscription_filter destination_arn"
  }

  assert {
    condition     = aws_cloudwatch_log_subscription_filter.redis-subscription-filter-slow.distribution == "ByLogStream"
    error_message = "Invalid config for aws_cloudwatch_log_subscription_filter distribution"
  }

  assert {
    condition     = aws_cloudwatch_log_subscription_filter.redis-subscription-filter-slow.role_arn == "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CWLtoSubscriptionFilterRole"
    error_message = "Invalid config for aws_cloudwatch_log_subscription_filter role_arn"
  }
}
