mock_provider "aws" {
  alias = "domain-cdn"
}

mock_provider "aws" {
  alias = "domain"
}

override_data {
  target = data.aws_route53_zone.domain-root
  values = {
    count = 0
    name  = "my-application.uktrade.digital"
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
    condition     = aws_acm_certificate.certificate.domain_name == "dom-prefix.env.app.uktrade.digital"
    error_message = "Should be: dom-prefix.env.app.uktrade.digital"
  }

}

run "aws_cloudfront_distribution_unit_test" {
  command = plan

  assert {
    condition     = [for k in aws_cloudfront_distribution.standard["dev.my-application.uktrade.digital"].aliases : true if k == "dev.my-application.uktrade.digital"][0] == true
    error_message = "Should be: [ dev.my-application.uktrade.digital, ]"
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
