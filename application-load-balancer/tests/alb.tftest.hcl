mock_provider "aws" {
  alias = "prod"
}

mock_provider "aws" {
  alias = "dev"
}

mock_provider "aws" {
  alias = "sandbox"
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
override_data {
  target = data.aws_route53_zone.domain-root-prod
  values = {
    count = 1
    name  = "dom-prefix-root-prod.env.app.uktrade.digital"
  }
}
override_data {
  target = data.aws_route53_zone.domain-alb-prod
  values = {
    count = 1
    name  = "dom-prefix-alb-prod.env.app.uktrade.digital"
  }
}


variables {
  application = "app"
  environment = "env"
  vpc_name    = "vpc-name"
  config = {
    domain_prefix    = "dom-prefix",
    cdn_domains_list = { "dev.my-application.uktrade.digital" : "my-application.uktrade.digital" },
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
    error_message = "Invalid value for for aws_lb.this load_balancer_type parameter, should be: application"
  }

  assert {
    condition     = [for el in aws_lb.this.subnets : el][0] == "subnet-000111222aaabbb01"
    error_message = "Invalid value for for aws_lb.this subnets parameter, should be: subnet-000111222aaabbb01"
  }

  assert {
    condition     = aws_lb.this.access_logs[0].bucket == "dbt-access-logs"
    error_message = "Invalid value for for aws_lb.this access_logs.bucket parameter, should be: dbt-access-logs"
  }

  assert {
    condition     = aws_lb.this.access_logs[0].prefix == "app/env"
    error_message = "Invalid value for for aws_lb.this access_logs.prefix parameter, should be: app/env"
  }

  assert {
    condition     = aws_lb.this.access_logs[0].enabled == true
    error_message = "Invalid value for for aws_lb.this access_logs.enabled parameter, should be: true"
  }
}

run "aws_lb_listener_http_unit_test" {
  command = plan

  assert {
    condition     = aws_lb_listener.alb-listener["http"].port == 80
    error_message = "Invalid port for aws_lb_listener.alb-listener.http, should be: 80"
  }

  assert {
    condition     = aws_lb_listener.alb-listener["http"].protocol == "HTTP"
    error_message = "Invalid value for aws_lb_listener.alb-listener.http protocol parameter, should be: HTTP"
  }

  assert {
    condition     = aws_lb_listener.alb-listener["http"].default_action[0].type == "forward"
    error_message = "Invalid value for aws_lb_listener.alb-listener.http default_action.type parameter, should be: forward"
  }
}

run "aws_lb_listener_https_unit_test" {
  command = plan

  assert {
    condition     = aws_lb_listener.alb-listener["https"].port == 443
    error_message = "Invalid port for aws_lb_listener.alb-listener.http, should be: 443"
  }

  assert {
    condition     = aws_lb_listener.alb-listener["https"].protocol == "HTTPS"
    error_message = "Invalid value for aws_lb_listener.alb-listener.http protocol parameter, should be: HTTPS"
  }

  assert {
    condition     = aws_lb_listener.alb-listener["https"].ssl_policy == "ELBSecurityPolicy-2016-08"
    error_message = "Invalid value for aws_lb_listener.alb-listener.http ssl_policy parameter, should be:ELBSecurityPolicy-2016-08"
  }

  assert {
    condition     = aws_lb_listener.alb-listener["https"].default_action[0].type == "forward"
    error_message = "Invalid value for aws_lb_listener.alb-listener.https default_action.type parameter, should be: forward"
  }
}

run "aws_security_group_http_unit_test" {
  command = plan

  assert {
    condition     = aws_security_group.alb-security-group["http"].name == "app-env-alb-http"
    error_message = "Invalid name for aws_security_group.alb-security-group.http, should be: app-env-alb-http"
  }

  assert {
    condition     = aws_security_group.alb-security-group["http"].revoke_rules_on_delete == false
    error_message = "Invalid value for aws_security_group.alb-security-group.http revoke_rules_on_delete parameter, should be: false"
  }

  assert {
    condition     = aws_security_group.alb-security-group["http"].vpc_id == "vpc-00112233aabbccdef"
    error_message = "Invalid value for aws_security_group.alb-security-group.http vpc_id parameter, should be: vpc-00112233aabbccdef"
  }
}

run "aws_security_group_https_unit_test" {
  command = plan

  assert {
    condition     = aws_security_group.alb-security-group["https"].name == "app-env-alb-https"
    error_message = "Invalid name for aws_security_group.alb-security-group.https, should be: app-env-alb-https"
  }

  assert {
    condition     = aws_security_group.alb-security-group["https"].revoke_rules_on_delete == false
    error_message = "Invalid value for aws_security_group.alb-security-group.https revoke_rules_on_delete parameter, should be: false"
  }

  assert {
    condition     = aws_security_group.alb-security-group["https"].vpc_id == "vpc-00112233aabbccdef"
    error_message = "Invalid value for aws_security_group.alb-security-group.https vpc_id parameter, should be: vpc-00112233aabbccdef"
  }
}

run "aws_lb_target_group_unit_test" {
  command = plan

  assert {
    condition     = aws_lb_target_group.http-target-group.name == "app-env-http"
    error_message = "Invalid name for aws_lb_target_group.http-target-group, should be: app-env-http"
  }

  assert {
    condition     = aws_lb_target_group.http-target-group.port == 80
    error_message = "Invalid value for aws_lb_target_group.http-target-group port parameter, should be: 80"
  }

  assert {
    condition     = aws_lb_target_group.http-target-group.protocol == "HTTP"
    error_message = "Invalid value for aws_lb_target_group.http-target-group protocol parameter, should be: HTTP"
  }

  assert {
    condition     = aws_lb_target_group.http-target-group.target_type == "ip"
    error_message = "Invalid value for aws_lb_target_group.http-target-group target_type parameter, should be: ip"
  }

  assert {
    condition     = aws_lb_target_group.http-target-group.vpc_id == "vpc-00112233aabbccdef"
    error_message = "Invalid value for aws_lb_target_group.http-target-group vpc_id parameter, should be: vpc-00112233aabbccdef"
  }
}

run "aws_acm_certificate_unit_test" {
  command = plan

  assert {
    condition     = aws_acm_certificate.certificate.domain_name == "dom-prefix.env.app.uktrade.digital"
    error_message = "Invalid name for aws_acm_certificate.certificate, should be: dom-prefix.env.app.uktrade.digital"
  }

  assert {
    condition     = length(aws_acm_certificate.certificate.subject_alternative_names) == 2
    error_message = "Invalid number of subject_alternative_names for aws_acm_certificate.certificate, should be: 2"
  }

  assert {
    condition     = [for el in aws_acm_certificate.certificate.subject_alternative_names : true if el == "dev.my-application.uktrade.digital"][0] == true
    error_message = "Invalid value for aws_acm_certificate.certificate subject_alternative_names parameter, should be either: dev.my-application.uktrade.digital or dom-prefix.env.app.uktrade.digital"
  }

  assert {
    condition     = [for el in aws_acm_certificate.certificate.subject_alternative_names : true if el == "dom-prefix.env.app.uktrade.digital"][0] == true
    error_message = "Invalid value for aws_acm_certificate.certificate subject_alternative_names parameter, should be either: dev.my-application.uktrade.digital or dom-prefix.env.app.uktrade.digital"
  }

  assert {
    condition     = aws_acm_certificate.certificate.validation_method == "DNS"
    error_message = "Invalid value for aws_acm_certificate.certificate validation_method parameter, should be: DNS"
  }

  assert {
    condition     = aws_acm_certificate.certificate.key_algorithm == "RSA_2048"
    error_message = "Invalid value for aws_acm_certificate.certificate key_algorithm parameter, should be: RSA_2048"
  }
}

run "aws_route53_record_unit_test" {
  command = plan

  assert {
    condition     = aws_route53_record.validation-record-san[0].ttl == 300
    error_message = "Invalid value for aws_route53_record.validation-record-san ttl parameter, should be: 300"
  }

  assert {
    condition     = aws_route53_record.validation-record-san[1].ttl == 300
    error_message = "Invalid value for aws_route53_record.validation-record-san ttl parameter, should be: 300"
  }

  assert {
    condition     = aws_route53_record.alb-record[0].name == "dom-prefix.env.app.uktrade.digital"
    error_message = "Invalid value for aws_route53_record.validation-record-san name parameter, should be: dom-prefix.env.app.uktrade.digital"
  }

  assert {
    condition     = aws_route53_record.alb-record[0].ttl == 300
    error_message = "Invalid value for aws_route53_record.alb-record[0] ttl parameter, should be: 300"
  }

  assert {
    condition     = aws_route53_record.alb-record[0].type == "CNAME"
    error_message = "Invalid value for aws_route53_record.alb-record[0] type parameter, should be: CNAME"
  }
}

run "aws_route53_record_prod_unit_test" {
  variables {
    application = "prod-app"
    environment = "prod"
    vpc_name    = "vpc-name"
    config = {
      domain_prefix    = "dom-prefix",
      cdn_domains_list = { "dev.my-application.uktrade.digital" : "my-application.uktrade.digital" },
    }
  }

  command = plan

  assert {
    condition     = aws_route53_record.validation-record-prod[0].ttl == 300
    error_message = "Invalid value for aws_route53_record.validation-record-prod ttl parameter, should be: 300"
  }

  assert {
    condition     = aws_route53_record.validation-record-prod[1].ttl == 300
    error_message = "Invalid value for aws_route53_record.validation-record-prod ttl parameter, should be: 300"
  }

  assert {
    condition     = aws_route53_record.alb-record-prod[0].name == "dom-prefix.prod-app.prod.uktrade.digital"
    error_message = "Invalid value for aws_route53_record.alb-record-prod[0] name parameter, should be: dom-prefix.prod-app.prod.uktrade.digital"
  }

  assert {
    condition     = aws_route53_record.alb-record-prod[0].ttl == 300
    error_message = "Invalid value for aws_route53_record.alb-record-prod[0] ttl parameter, should be: 300"
  }

  assert {
    condition     = aws_route53_record.alb-record-prod[0].type == "CNAME"
    error_message = "Invalid value for aws_route53_record.alb-record-prod[0] type parameter, should be: CNAME"
  }
}
