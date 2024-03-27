variables {
  vpc_name    = "test-vpc"
  application = "test-application"
  environment = "test-environment"
  config = {
    enable_ops_center = true
  }
}

run "everything_on_test" {
  command = plan

  assert {
    condition     = length(aws_cloudwatch_dashboard.compute) == 1
    error_message = "dashboard has not been created"
  }

  assert {
    condition     = aws_cloudwatch_dashboard.compute[0].dashboard_name == "test-application-test-environment-compute"
    error_message = "dashboard_name is incorrect"
  }
}

