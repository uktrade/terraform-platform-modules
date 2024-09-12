variables {
  vpc_name    = "s3-test-vpc-name"
  application = "s3-test-application"
  environment = "s3-test-environment"
  name        = "s3-test-name"
  config = {
    "bucket_name" = "dbt-terraform-test-s3-module",
    "type"        = "string",
    "versioning"  = false,
    "objects"     = [],
  }
}

mock_provider "aws" {
  alias = "domain-cdn"
}

mock_provider "aws" {
  alias = "domain"
}

run "aws_s3_bucket_unit_test" {
  command = plan

  assert {
    condition     = output.bucket_name == "dbt-terraform-test-s3-module"
    error_message = "Should be: dbt-terraform-test-s3-module"
  }

  assert {
    condition     = aws_s3_bucket.this.bucket == "dbt-terraform-test-s3-module"
    error_message = "Invalid name for aws_s3_bucket"
  }

  assert {
    condition     = aws_s3_bucket.this.force_destroy == false
    error_message = "Should be: false."
  }

  assert {
    condition     = aws_s3_bucket.this.tags["environment"] == "s3-test-environment"
    error_message = "Invalid value for aws_s3_bucket tags parameter."
  }

  assert {
    condition     = aws_s3_bucket.this.tags["application"] == "s3-test-application"
    error_message = "Invalid value for aws_s3_bucket tags parameter."
  }

  assert {
    condition     = aws_s3_bucket.this.tags["copilot-application"] == "s3-test-application"
    error_message = "Invalid value for aws_s3_bucket tags parameter."
  }

  assert {
    condition     = aws_s3_bucket.this.tags["copilot-environment"] == "s3-test-environment"
    error_message = "Invalid value for aws_s3_bucket tags parameter."
  }

  assert {
    condition     = aws_s3_bucket.this.tags["managed-by"] == "DBT Platform - Terraform"
    error_message = "Invalid value for aws_s3_bucket tags parameter."
  }

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.lifecycle-configuration == []
    error_message = "Should be: []"
  }

}

run "aws_iam_policy_document_unit_test" {
  command = plan

  assert {
    condition     = [for el in data.aws_iam_policy_document.bucket-policy.statement[0].condition : true if el.variable == "aws:SecureTransport"][0] == true
    error_message = "Should be: aws:SecureTransport"
  }

  assert {
    condition     = data.aws_iam_policy_document.bucket-policy.statement[0].effect == "Deny"
    error_message = "Should be: Deny"
  }

  assert {
    condition     = [for el in data.aws_iam_policy_document.bucket-policy.statement[0].actions : true if el == "s3:*"][0] == true
    error_message = "Should be: s3:*"
  }
}

run "aws_s3_bucket_versioning_unit_test" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.this-versioning.versioning_configuration[0].status == "Disabled"
    error_message = "Should be: Disabled"
  }
}

run "aws_kms_key_unit_test" {
  command = plan

  assert {
    condition     = aws_kms_key.kms-key[0].bypass_policy_lockout_safety_check == false
    error_message = "Should be: false"
  }

  assert {
    condition     = aws_kms_key.kms-key[0].customer_master_key_spec == "SYMMETRIC_DEFAULT"
    error_message = "Should be: SYMMETRIC_DEFAULT"
  }

  assert {
    condition     = aws_kms_key.kms-key[0].enable_key_rotation == false
    error_message = "Should be: false"
  }

  assert {
    condition     = aws_kms_key.kms-key[0].is_enabled == true
    error_message = "Should be: true"
  }

  assert {
    condition     = aws_kms_key.kms-key[0].key_usage == "ENCRYPT_DECRYPT"
    error_message = "Should be: ENCRYPT_DECRYPT"
  }

  assert {
    condition     = aws_kms_key.kms-key[0].tags["application"] == "s3-test-application"
    error_message = "Invalid value for aws_kms_key tags parameter."
  }

  assert {
    condition     = aws_kms_key.kms-key[0].tags["environment"] == "s3-test-environment"
    error_message = "Invalid value for aws_kms_key tags parameter."
  }
}

run "aws_kms_alias_unit_test" {
  command = plan

  assert {
    condition     = aws_kms_alias.s3-bucket[0].name == "alias/s3-test-application-s3-test-environment-dbt-terraform-test-s3-module-key"
    error_message = "Should be: alias/s3-test-application-s3-test-environment-dbt-terraform-test-s3-module-key"
  }
}

run "aws_s3_bucket_server_side_encryption_configuration_unit_test" {
  command = plan

  assert {
    condition     = [for el in aws_s3_bucket_server_side_encryption_configuration.encryption-config[0].rule : true if[for el2 in el.apply_server_side_encryption_by_default : true if el2.sse_algorithm == "aws:kms"][0] == true][0] == true
    error_message = "Invalid value for aws_s3_bucket_server_side_encryption_configuration tags parameter."
  }
}

run "aws_s3_bucket_versioning_enabled_unit_test" {
  command = plan

  variables {
    config = {
      "bucket_name" = "dbt-terraform-test-s3-module",
      "type"        = "string",
      "versioning"  = true,
      "objects"     = [],
    }
  }

  ### Test aws_s3_bucket_versioning resource ###
  assert {
    condition     = aws_s3_bucket_versioning.this-versioning.versioning_configuration[0].status == "Enabled"
    error_message = "Should be: Enabled"
  }
}

run "aws_s3_bucket_lifecycle_configuration_unit_test" {
  command = plan

  variables {
    config = {
      "bucket_name"     = "dbt-terraform-test-s3-module",
      "type"            = "string",
      "lifecycle_rules" = [{ "filter_prefix" = "/foo", "expiration_days" = 90, "enabled" = true }],
      "objects"         = [],
    }
  }

  ### Test aws_s3_bucket_lifecycle_configuration resource ###
  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.lifecycle-configuration[0].rule[0].filter[0].prefix == "/foo"
    error_message = "Should be: /foo"
  }

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.lifecycle-configuration[0].rule[0].expiration[0].days == 90
    error_message = "Should be: 90"
  }

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.lifecycle-configuration[0].rule[0].abort_incomplete_multipart_upload[0].days_after_initiation == 7
    error_message = "Should be: 7"
  }

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.lifecycle-configuration[0].rule[0].status == "Enabled"
    error_message = "Should be: Enabled"
  }
}

run "aws_s3_bucket_lifecycle_configuration_no_prefix_unit_test" {
  command = plan

  variables {
    config = {
      "bucket_name"     = "dbt-terraform-test-s3-module",
      "type"            = "string",
      "lifecycle_rules" = [{ "expiration_days" = 90, "enabled" = true }],
      "objects"         = [],
    }
  }

  ### Test aws_s3_bucket_lifecycle_configuration resource when no prefix is used ###
  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.lifecycle-configuration[0].rule[0].filter[0] != null
    error_message = "Should be: {}"
  }

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.lifecycle-configuration[0].rule[0].filter[0].prefix == null
    error_message = "Should be: null"
  }
}

run "aws_s3_bucket_data_migration_unit_test" {
  command = plan

  variables {
    config = {
      "bucket_name" = "dbt-terraform-test-s3-cross-account",
      "type"        = "s3",
      "data_migration" = {
        "import" = {
          "worker_role_arn"    = "arn:aws:iam::1234:role/service-role/my-privileged-arn",
          "source_kms_key_arn" = "arn:aws:iam::1234:my-external-kms-key-arn",
          "source_bucket_arn"  = "arn:aws:s3::1234:my-source-bucket"
        }
      }
    }
  }

  assert {
    condition     = module.data_migration[0].module_exists
    error_message = "data migration module should be created"
  }
}

run "aws_s3_bucket_not_data_migration_unit_test" {
  command = plan

  variables {
    config = {
      "bucket_name" = "dbt-terraform-test-s3-not-x-account",
      "type"        = "s3",
    }
  }

  assert {
    condition     = length(module.data_migration) == 0
    error_message = "data migration module should not be created"
  }
}

run "aws_s3_bucket_object_lock_configuration_governance_unit_test" {
  command = plan

  variables {
    config = {
      "bucket_name"      = "dbt-terraform-test-s3-module",
      "type"             = "string",
      "versioning"       = true,
      "retention_policy" = { "mode" = "GOVERNANCE", "days" = 1 },
      "objects"          = [],
    }
  }

  assert {
    condition     = [for el in aws_s3_bucket_object_lock_configuration.object-lock-config[0].rule : true if el.default_retention[0].mode == "GOVERNANCE"][0] == true
    error_message = "Should be: GOVERNANCE"
  }

  assert {
    condition     = [for el in aws_s3_bucket_object_lock_configuration.object-lock-config[0].rule : true if el.default_retention[0].days == 1][0] == true
    error_message = "Should be: 1"
  }
}

run "aws_s3_bucket_object_lock_configuration_compliance_unit_test" {
  command = plan

  variables {
    config = {
      "bucket_name"      = "dbt-terraform-test-s3-module",
      "type"             = "string",
      "versioning"       = true,
      "retention_policy" = { "mode" = "COMPLIANCE", "years" = 1 },
      "objects"          = [],
    }
  }

  assert {
    condition     = [for el in aws_s3_bucket_object_lock_configuration.object-lock-config[0].rule : true if el.default_retention[0].mode == "COMPLIANCE"][0] == true
    error_message = "Invalid s3 bucket object lock configuration"
  }

  assert {
    condition     = [for el in aws_s3_bucket_object_lock_configuration.object-lock-config[0].rule : true if el.default_retention[0].years == 1][0] == true
    error_message = "Invalid s3 bucket object lock configuration"
  }
}

run "aws_s3_bucket_object_lock_configuration_nopolicy_unit_test" {
  command = plan

  variables {
    config = {
      "bucket_name" = "dbt-terraform-test-s3-module",
      "type"        = "string",
      "versioning"  = true,
      "objects"     = [],
    }
  }

  ### Test aws_s3_bucket_object_lock_configuration resource ###
  assert {
    condition     = aws_s3_bucket_object_lock_configuration.object-lock-config == []
    error_message = "Invalid s3 bucket object lock configuration"
  }
}

run "aws_cloudfront_origin_access_control_unit_test" {
  command = plan

  variables {
    config = {
      "bucket_name" = "test",
      "type"        = "string",
      "serve_static" = true,
      "objects"     = [],
    }
  }

  assert {
    condition     = aws_cloudfront_origin_access_control.oac[0].name == "oac"
    error_message = "Invalid value for aws_cloudfront_origin_access_control name."
  }

  assert {
    condition     = aws_cloudfront_origin_access_control.oac[0].description == "Origin access control for Cloudfront distribution and test.s3-test-environment.s3-test-application.uktrade.digital static s3 bucket."
    error_message = "Invalid value for aws_cloudfront_origin_access_control name."
  }

  assert {
    condition     = aws_cloudfront_origin_access_control.oac[0].origin_access_control_origin_type == "s3"
    error_message = "Invalid value for aws_cloudfront_origin_access_control origin type."
  }

  assert {
    condition     = aws_cloudfront_origin_access_control.oac[0].signing_behavior == "always"
    error_message = "Invalid value for aws_cloudfront_origin_access_control signing_behavior."
  }

  assert {
    condition     = aws_cloudfront_origin_access_control.oac[0].signing_protocol == "sigv4"
    error_message = "Invalid value for aws_cloudfront_origin_access_control signing protocol."
  }
}

run "aws_acm_certificate_unit_test" {
  command = plan

  variables {
    config = {
      "bucket_name" = "test",
      "serve_static" = true,
      "type"        = "string",
      "objects"     = [],
    }
  }

  assert {
    condition     = aws_acm_certificate.certificate[0].domain_name == "test.s3-test-environment.s3-test-application.uktrade.digital"
    error_message = "Invalid value for aws_acm_certificate domain name."
  }

  assert {
    condition     = aws_acm_certificate.certificate[0].validation_method == "DNS"
    error_message = "Invalid value for aws_acm_certificate validation method."
  }

  assert {
    condition     = aws_acm_certificate.certificate[0].tags["application"] == "s3-test-application"
    error_message = "Invalid value for aws_acm_certificate tags parameter."
  }

  assert {
    condition     = aws_acm_certificate.certificate[0].tags["environment"] == "s3-test-environment"
    error_message = "Invalid value for aws_acm_certificate tags parameter."
  }

  assert {
    condition     = aws_acm_certificate.certificate[0].tags["application"] == "s3-test-application"
    error_message = "Invalid value for aws_acm_certificate tags parameter."
  }

  assert {
    condition     = aws_acm_certificate.certificate[0].tags["copilot-application"] == "s3-test-application"
    error_message = "Invalid value for aws_acm_certificate tags parameter."
  }

  assert {
    condition     = aws_acm_certificate.certificate[0].tags["copilot-environment"] == "s3-test-environment"
    error_message = "Invalid value for aws_acm_certificate tags parameter."
  }

  assert {
    condition     = aws_acm_certificate.certificate[0].tags["managed-by"] == "DBT Platform - Terraform"
    error_message = "Invalid value for aws_acm_certificate tags parameter."
  }
}

run "aws_route53_record_cert_validation_unit_test" {
  command = plan

  variables {
    config = {
      "bucket_name" = "test",
      "serve_static" = true,
      "type"        = "string",
      "objects"     = [],
    }
  }

  # assert {
  #   condition     = aws_route53_record.cert_validation[0].type == "CNAME"
  #   error_message = "Invalid value for aws_route53_record cert validation type."
  # }

  assert {
    condition     = aws_route53_record.cert_validation[0].ttl == 60
    error_message = "Invalid TTL value for aws_route53_record cert validation."
  }
}

# ADD E2E for aws_acm_certificate_validation

run "aws_route53_record_cloudfront_domain_unit_test" {
  command = plan

  variables {
    config = {
      "bucket_name" = "test",
      "serve_static" = true,
      "type"        = "string",
      "objects"     = [],
    }
  }

  # assert {
  #   condition     = aws_route53_record.cloudfront_domain[0].name == aws_s3_bucket.this.bucket
  #   error_message = "Route 53 record name should match the S3 bucket name."
  # } MOVE TO E2E

  assert {
    condition     = aws_route53_record.cloudfront_domain[0].type == "A"
    error_message = "Route 53 record type should be 'A'."
  }

  # assert {
  #   condition     = aws_route53_record.cloudfront_domain[0].zone_id == data.aws_route53_zone.selected[0].id
  #   error_message = "Route 53 record zone ID should match the selected Route 53 zone ID."
  # } MOVE TO E2E

  # assert {
  #   condition     = aws_route53_record.cloudfront_domain[0].alias[0].name == aws_cloudfront_distribution.s3_distribution[0].domain_name
  #   error_message = "Route 53 alias name should match the CloudFront distribution domain name."
  # } MOVE TO E2E

  # assert {
  #   condition     = aws_route53_record.cloudfront_domain[0].alias[0].zone_id == aws_cloudfront_distribution.s3_distribution[0].hosted_zone_id
  #   error_message = "Route 53 alias zone ID should match the CloudFront distribution hosted zone ID."
  # } MOVE TO E2E

  assert {
    condition     = aws_route53_record.cloudfront_domain[0].alias[0].evaluate_target_health == false
    error_message = "Route 53 alias should not evaluate target health."
  }

}


run "aws_cloudfront_origin_request_policy_unit_test" {
  command = plan 

  variables {
    config = {
      "bucket_name" = "test",
      "serve_static" = true,
      "type"        = "string",
      "objects"     = [],
    }
  }

  assert {
    condition     = aws_cloudfront_origin_request_policy.forward_content_type[0].name == "ForwardContentTypePolicy"
    error_message = "CloudFront Origin Request Policy name should be 'ForwardContentTypePolicy'."
  }

  assert {
    condition     = aws_cloudfront_origin_request_policy.forward_content_type[0].headers_config[0].header_behavior == "whitelist" && contains(aws_cloudfront_origin_request_policy.forward_content_type[0].headers_config[0].headers[0].items, "Content-Type")
    error_message = "CloudFront Origin Request Policy should whitelist the 'Content-Type' header."
  }

  assert {
    condition     = aws_cloudfront_origin_request_policy.forward_content_type[0].query_strings_config[0].query_string_behavior == "none"
    error_message = "CloudFront Origin Request Policy should have 'none' as the query_string_behavior."
  }

  assert {
    condition     = aws_cloudfront_origin_request_policy.forward_content_type[0].cookies_config[0].cookie_behavior == "none"
    error_message = "CloudFront Origin Request Policy should have 'none' as the cookie_behavior."
  }

}



run "aws_cloudfront_distribution_unit_test" {
  command = plan

  variables {
    config = {
      "bucket_name" = "test",
      "serve_static" = true,
      "type"        = "string",
      "objects"     = [],
    }
  }

  assert {
    condition     = aws_cloudfront_distribution.s3_distribution[0].enabled == true
    error_message = "CloudFront distribution should be enabled."
  }

  assert {
    condition     = contains(aws_cloudfront_distribution.s3_distribution[0].aliases, "test.s3-test-environment.s3-test-application.uktrade.digital")
    error_message = "CloudFront distribution should include the correct alias."
  }

  assert {
    condition     = length(aws_cloudfront_distribution.s3_distribution[0].default_cache_behavior[0].allowed_methods) == 2 && contains(aws_cloudfront_distribution.s3_distribution[0].default_cache_behavior[0].allowed_methods, "GET") && contains(aws_cloudfront_distribution.s3_distribution[0].default_cache_behavior[0].allowed_methods, "HEAD")
    error_message = "Cloudfront distribution default_cache_behavior allowed methods should contain GET and HEAD."
  }

  assert {
    condition     = length(aws_cloudfront_distribution.s3_distribution[0].default_cache_behavior[0].cached_methods) == 2 && contains(aws_cloudfront_distribution.s3_distribution[0].default_cache_behavior[0].cached_methods, "GET") && contains(aws_cloudfront_distribution.s3_distribution[0].default_cache_behavior[0].cached_methods, "HEAD")
    error_message = "Cloudfront distribution default_cache_behavior cached methods should contain GET and HEAD."
  }

  assert {
    condition     = aws_cloudfront_distribution.s3_distribution[0].default_cache_behavior[0].viewer_protocol_policy == "redirect-to-https"
    error_message = "CloudFront should enforce HTTPS."
  }

  assert {
    condition     = aws_cloudfront_distribution.s3_distribution[0].viewer_certificate[0].ssl_support_method == "sni-only"
    error_message = "Cloudfront viewer certificate ssl support method should be sni-only."
  }

  assert {
    condition     = aws_cloudfront_distribution.s3_distribution[0].viewer_certificate[0].minimum_protocol_version == "TLSv1.2_2021"
    error_message = "Cloudfront viewer certificate minimum_protocol_version should be TLSv1.2_2021."
  }

  assert {
    condition     = aws_cloudfront_distribution.s3_distribution[0].restrictions[0].geo_restriction[0].restriction_type == "none"
    error_message = "Cloudfront geo restrictions should be none."
  }

  assert {
    condition     = aws_ssm_parameter.cloudfront_alias[0].tags["environment"] == "s3-test-environment"
    error_message = "Invalid value for aws_s3_bucket tags parameter."
  }

  assert {
    condition     = aws_ssm_parameter.cloudfront_alias[0].tags["application"] == "s3-test-application"
    error_message = "Invalid value for aws_s3_bucket tags parameter."
  }

  assert {
    condition     = aws_ssm_parameter.cloudfront_alias[0].tags["copilot-application"] == "s3-test-application"
    error_message = "Invalid value for aws_s3_bucket tags parameter."
  }

  assert {
    condition     = aws_ssm_parameter.cloudfront_alias[0].tags["copilot-environment"] == "s3-test-environment"
    error_message = "Invalid value for aws_s3_bucket tags parameter."
  }

  assert {
    condition     = aws_ssm_parameter.cloudfront_alias[0].tags["managed-by"] == "DBT Platform - Terraform"
    error_message = "Invalid value for aws_s3_bucket tags parameter."
  }
}

# run "aws_s3_bucket_policy_cloudfront_unit_test" {    TEST IN E2E instead
#   command = plan

#   variables {
#     config = {
#       "bucket_name" = "test",
#       "serve_static" = true,
#       "type"        = "string",
#       "objects"     = [],
#     }
#   }

#   assert {
#     condition     = contains(tolist([aws_s3_bucket_policy.cloudfront_bucket_policy[0].policy]), "cloudfront.amazonaws.com")
#     error_message = "S3 bucket policy should allow CloudFront access."
#   }
# }


# run "aws_kms_key_policy_s3_ssm_kms_key_policy_test" {   TEST IN E2E
#   command = plan

#   variables {
#     config = {
#       "bucket_name" = "test",
#       "serve_static" = true,
#       "type"        = "string",
#       "objects"     = [],
#     }
#   }

#   assert {
#     condition     = aws_kms_key_policy.s3-ssm-kms-key-policy[0].policy != null
#     error_message = "KMS key policy should contain a valid policy document."
#   }

#   assert {
#     condition     = contains(aws_kms_key_policy.s3-ssm-kms-key-policy[0].policy, "ssm.amazonaws.com")
#     error_message = "KMS key policy should allow access to ssm.amazonaws.com."
#   }

#   assert {
#     condition     = contains(aws_kms_key_policy.s3-ssm-kms-key-policy[0].policy, "kms:Decrypt")
#     error_message = "KMS key policy should allow kms:Decrypt action."
#   }

#   assert {
#     condition     = contains(aws_kms_key_policy.s3-ssm-kms-key-policy[0].policy, "kms:GenerateDataKey*")
#     error_message = "KMS key policy should allow kms:GenerateDataKey* action."
#   }

#   assert {
#     condition     = contains(aws_kms_key_policy.s3-ssm-kms-key-policy[0].policy, "/copilot/s3-test-application/s3-test-environment/secrets/STATIC_S3_ENDPOINT")
#     error_message = "KMS key policy should include the correct SSM parameter name for encryption context."
#   }

#   assert {
#     condition     = contains(aws_kms_key_policy.s3-ssm-kms-key-policy[0].policy, "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root")
#     error_message = "KMS key policy should allow root account full access."
#   }
# }


run "aws_ssm_parameter_cloudfront_alias_unit_test" {
  command = plan

  variables {
    config = {
      "bucket_name" = "test",
      "serve_static" = true,
      "type"        = "string",
      "objects"     = [],
    }
  }

  assert {
    condition     = aws_ssm_parameter.cloudfront_alias[0].name == "/copilot/s3-test-application/s3-test-environment/secrets/STATIC_S3_ENDPOINT"
    error_message = "Invalid name for aws_ssm_parameter cloudfront alias."
  }

  assert {
    condition     = aws_ssm_parameter.cloudfront_alias[0].type == "SecureString"
    error_message = "Invalid type for aws_ssm_parameter cloudfront alias."
  }

  assert {
    condition     = aws_ssm_parameter.cloudfront_alias[0].value == "test.s3-test-environment.s3-test-application.uktrade.digital"
    error_message = "Invalid  value for aws_ssm_parameter cloudfront alias."
  }

  assert {
    condition     = aws_ssm_parameter.cloudfront_alias[0].tags["environment"] == "s3-test-environment"
    error_message = "Invalid value for aws_s3_bucket tags parameter."
  }

  assert {
    condition     = aws_ssm_parameter.cloudfront_alias[0].tags["application"] == "s3-test-application"
    error_message = "Invalid value for aws_s3_bucket tags parameter."
  }

  assert {
    condition     = aws_ssm_parameter.cloudfront_alias[0].tags["copilot-application"] == "s3-test-application"
    error_message = "Invalid value for aws_s3_bucket tags parameter."
  }

  assert {
    condition     = aws_ssm_parameter.cloudfront_alias[0].tags["copilot-environment"] == "s3-test-environment"
    error_message = "Invalid value for aws_s3_bucket tags parameter."
  }

  assert {
    condition     = aws_ssm_parameter.cloudfront_alias[0].tags["managed-by"] == "DBT Platform - Terraform"
    error_message = "Invalid value for aws_s3_bucket tags parameter."
  }

}
