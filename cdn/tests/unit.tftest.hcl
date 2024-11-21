mock_provider "aws" {
  alias = "domain-cdn"
}

mock_provider "aws" {
  alias = "domain"
}

mock_provider "aws" {

}

override_data {
  target = data.aws_route53_zone.domain-root
  values = {
    count = 0
    name  = "my-application.uktrade.digital"
  }
}

override_data {
  target = data.aws_secretsmanager_secret_version.origin_verify_secret_version
  values = {
    secret_string = "{\"HEADERVALUE\": \"dummy123\"}"
  }
}


variables {
  application = "app"
  environment = "env"
  vpc_name    = "vpc-name"
  config = {
    domain_prefix    = "dom-prefix",
    cdn_domains_list = { "dev.my-application.uktrade.digital" : ["internal", "my-application.uktrade.digital"], "dev2.my-application.uktrade.digital" : ["internal", "my-application.uktrade.digital", "disable_cdn"] }
  }
  origin_verify_secret_id = "dummy123"
}


run "aws_route53_record_unit_test" {
  command = plan

  assert {
    condition     = aws_route53_record.cdn-address["dev.my-application.uktrade.digital"].name == "dev.my-application.uktrade.digital"
    error_message = "Should be: dev.my-application.uktrade.digital"
  }

}

run "aws_acm_certificate_unit_test" {
  command = plan

  assert {
    condition     = aws_acm_certificate.certificate["dev.my-application.uktrade.digital"].domain_name == "dev.my-application.uktrade.digital"
    error_message = "Should be: dev.my-application.uktrade.digital"
  }

}

run "aws_cloudfront_distribution_unit_test" {
  command = plan

  assert {
    condition     = [for k in aws_cloudfront_distribution.standard["dev.my-application.uktrade.digital"].aliases : true if k == "dev.my-application.uktrade.digital"][0] == true
    error_message = "Should be: [ dev.my-application.uktrade.digital, ]"
  }

}

run "aws_cloudfront_distribution_custom_header_test" {
  command = plan

  assert {
    condition = [
      for origin in aws_cloudfront_distribution.standard["dev.my-application.uktrade.digital"].origin :
    true if[for header in origin.custom_header : true if header.name == "x-origin-verify" && header.value == "dummy123"] != []][0] == true
    error_message = "Custom header x-origin-verify with value 'dummy123' is missing or incorrectly configured."
  }
}

run "aws_route53_record_unit_test_prod" {
  command = plan

  variables {
    application = "app"
    environment = "prod"
    config = {
      domain_prefix    = "dom-prefix",
      cdn_domains_list = { "dev.my-application.uktrade.digital" : ["internal", "my-application.uktrade.digital"], "dev2.my-application.uktrade.digital" : ["internal", "my-application.uktrade.digital", "enable_record"] }
    }
  }

  assert {
    condition     = aws_route53_record.cdn-address["dev2.my-application.uktrade.digital"].name == "dev2.my-application.uktrade.digital"
    error_message = "Should be: dev2.my-application.uktrade.digital"
  }

}

run "domain_length_validation_tests" {
  command = plan

  variables {
    application = "app"
    environment = "env"
    config = {
      domain_prefix    = "dom-prefix",
      cdn_domains_list = { "a-very-long-domain-name-used-to-test-length-validation.my-application.uktrade.digital" : ["internal", "my-application.uktrade.digital"] }
    }
  }

  expect_failures = [
    var.config.cdn_domains_list
  ]
}

run "domain_length_validation_tests_succeed_with_empty_config" {
  command = plan

  variables {
    application = "app"
    environment = "env"
    config      = {}
  }

  assert {
    condition     = var.config.cdn_domains_list == null
    error_message = "Should be: null"
  }
}

run "cdn_read_timeout_is_set_to_30_seconds_by_default" {
  command = plan

  assert {
    condition = [
      for k in aws_cloudfront_distribution.standard["dev.my-application.uktrade.digital"].origin :
      k.custom_origin_config[0].origin_read_timeout
      if k.domain_name == "internal.env.app.uktrade.digital"
    ][0] == 30
    error_message = "Should be: 30 seconds"
  }
}

run "cdn_read_timeout_is_set_to_config_specified_value_when_provided" {
  command = plan

  variables {
    config = {
      cdn_domains_list    = { "dev.my-application.uktrade.digital" : ["internal", "my-application.uktrade.digital"] }
      cdn_timeout_seconds = 60
    }
  }


  assert {
    condition = [
      for k in aws_cloudfront_distribution.standard["dev.my-application.uktrade.digital"].origin :
      k.custom_origin_config[0].origin_read_timeout
      if k.domain_name == "internal.env.app.uktrade.digital"
    ][0] == 60
    error_message = "Should be: 60 seconds"
  }
}
