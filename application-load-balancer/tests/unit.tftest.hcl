mock_provider "aws" {}

mock_provider "aws" {
  alias = "sandbox"
}

mock_provider "aws" {
  alias = "domain"
}

override_data {
  target = data.aws_vpc.vpc
  values = {
    id         = "vpc-00112233aabbccdef"
    cidr_block = "10.0.0.0/16"
  }
}
override_data {
  target = data.aws_subnets.public-subnets
  values = {
    ids = ["subnet-000111222aaabbb01"]
  }
}
override_data {
  target = data.aws_route53_zone.domain-root
  values = {
    count = 0
    name  = "dom-prefix-root.env.app.uktrade.digital"
  }
}
override_data {
  target = data.aws_route53_zone.domain-alb
  values = {
    count = 0
    name  = "dom-prefix-alb.env.app.uktrade.digital"
  }
}


variables {
  application = "app"
  environment = "env"
  vpc_name    = "vpc-name"
  config = {
    domain_prefix = "dom-prefix",
    cdn_domains_list = {
      "web.dev.my-application.uktrade.digital" : ["internal", "my-application.uktrade.digital"]
      "api.dev.my-application.uktrade.digital" : ["internal", "my-application.uktrade.digital"]
    }
  }
}


run "aws_lb_unit_test" {
  command = plan

  assert {
    condition     = aws_lb.this.name == "app-env"
    error_message = "Invalid name for aws_lb.this"
  }

  assert {
    condition     = aws_lb.this.load_balancer_type == "application"
    error_message = "Should be: application"
  }

  assert {
    condition     = [for el in aws_lb.this.subnets : el][0] == "subnet-000111222aaabbb01"
    error_message = "Should be: subnet-000111222aaabbb01"
  }

  assert {
    condition     = aws_lb.this.access_logs[0].bucket == "dbt-access-logs"
    error_message = "Should be: dbt-access-logs"
  }

  assert {
    condition     = aws_lb.this.access_logs[0].prefix == "app/env"
    error_message = "Should be: app/env"
  }

  assert {
    condition     = aws_lb.this.access_logs[0].enabled == true
    error_message = "Should be: true"
  }
}

run "aws_lb_listener_http_unit_test" {
  command = plan

  assert {
    condition     = aws_lb_listener.alb-listener["http"].port == 80
    error_message = "Should be: 80"
  }

  assert {
    condition     = aws_lb_listener.alb-listener["http"].protocol == "HTTP"
    error_message = "Should be: HTTP"
  }

  assert {
    condition     = aws_lb_listener.alb-listener["http"].default_action[0].type == "forward"
    error_message = "Should be: forward"
  }
}

run "aws_lb_listener_https_unit_test" {
  command = plan

  assert {
    condition     = aws_lb_listener.alb-listener["https"].port == 443
    error_message = "Should be: 443"
  }

  assert {
    condition     = aws_lb_listener.alb-listener["https"].protocol == "HTTPS"
    error_message = "Should be: HTTPS"
  }

  assert {
    condition     = aws_lb_listener.alb-listener["https"].ssl_policy == "ELBSecurityPolicy-2016-08"
    error_message = "Should be:ELBSecurityPolicy-2016-08"
  }

  assert {
    condition     = aws_lb_listener.alb-listener["https"].default_action[0].type == "forward"
    error_message = "Should be: forward"
  }
}

run "aws_security_group_http_unit_test" {
  command = plan

  assert {
    condition     = aws_security_group.alb-security-group["http"].name == "app-env-alb-http"
    error_message = "Should be: app-env-alb-http"
  }

  # Can't test for the default on a plan
  # assert {
  #   condition     = aws_security_group.alb-security-group["http"].revoke_rules_on_delete == false
  #   error_message = "Should be: false"
  # }

  assert {
    condition     = aws_security_group.alb-security-group["http"].vpc_id == "vpc-00112233aabbccdef"
    error_message = "Should be: vpc-00112233aabbccdef"
  }
}

run "aws_security_group_https_unit_test" {
  command = plan

  assert {
    condition     = aws_security_group.alb-security-group["https"].name == "app-env-alb-https"
    error_message = "Should be: app-env-alb-https"
  }

  # Can't test for the default on a plan
  # assert {
  #   condition     = aws_security_group.alb-security-group["https"].revoke_rules_on_delete == false
  #   error_message = "Should be: false"
  # }

  assert {
    condition     = aws_security_group.alb-security-group["https"].vpc_id == "vpc-00112233aabbccdef"
    error_message = "Should be: vpc-00112233aabbccdef"
  }
}

run "aws_lb_target_group_unit_test" {
  command = plan

  assert {
    condition     = aws_lb_target_group.http-target-group.name == "app-env-http"
    error_message = "Should be: app-env-http"
  }

  assert {
    condition     = aws_lb_target_group.http-target-group.port == 80
    error_message = "Should be: 80"
  }

  assert {
    condition     = aws_lb_target_group.http-target-group.protocol == "HTTP"
    error_message = "Should be: HTTP"
  }

  assert {
    condition     = aws_lb_target_group.http-target-group.target_type == "ip"
    error_message = "Should be: ip"
  }

  assert {
    condition     = aws_lb_target_group.http-target-group.vpc_id == "vpc-00112233aabbccdef"
    error_message = "Should be: vpc-00112233aabbccdef"
  }
}

run "aws_acm_certificate_unit_test" {
  command = plan

  assert {
    condition     = aws_acm_certificate.certificate.domain_name == "dom-prefix.env.app.uktrade.digital"
    error_message = "Should be: dom-prefix.env.app.uktrade.digital"
  }

  assert {
    condition     = length(aws_acm_certificate.certificate.subject_alternative_names) == 2
    error_message = "Should be: 2"
  }

  assert {
    condition     = [for el in aws_acm_certificate.certificate.subject_alternative_names : true if el == "web.dev.my-application.uktrade.digital"][0] == true
    error_message = "Should be: web.dev.my-application.uktrade.digital"
  }

  assert {
    condition     = [for el in aws_acm_certificate.certificate.subject_alternative_names : true if el == "api.dev.my-application.uktrade.digital"][0] == true
    error_message = "Should be: api.dev.my-application.uktrade.digital"
  }

  # Todo: Understand this
  # assert {
  #   condition     = [for el in aws_acm_certificate.certificate.subject_alternative_names : true if el == "dom-prefix.env.app.uktrade.digital"][0] == true
  #   error_message = "Should be: either: dev.my-application.uktrade.digital or dom-prefix.env.app.uktrade.digital"
  # }

  assert {
    condition     = aws_acm_certificate.certificate.validation_method == "DNS"
    error_message = "Should be: DNS"
  }

  assert {
    condition     = aws_acm_certificate.certificate.key_algorithm == "RSA_2048"
    error_message = "Should be: RSA_2048"
  }
}

run "aws_route53_record_unit_test" {
  command = plan

  assert {
    condition     = aws_route53_record.validation-record-san[0].ttl == 300
    error_message = "Should be: 300"
  }

  assert {
    condition     = aws_route53_record.validation-record-san[1].ttl == 300
    error_message = "Should be: 300"
  }

  assert {
    condition     = aws_route53_record.alb-record.name == "dom-prefix.env.app.uktrade.digital"
    error_message = "Should be: dom-prefix.env.app.uktrade.digital"
  }

  assert {
    condition     = aws_route53_record.alb-record.ttl == 300
    error_message = "Should be: 300"
  }

  assert {
    condition     = aws_route53_record.alb-record.type == "CNAME"
    error_message = "Should be: CNAME"
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
