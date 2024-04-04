variables {
  vpc_name    = "test-vpc"
  application = "test-application"
  environment = "test-environment"
  config = {
    enable_ops_center = true
  }
}

run "test_compute_dashboard_is_created" {
  command = plan

  variables {
    application = "my-app"
    environment = "my-env"
    vpc_name    = "terraform-tests-vpc"

    config = {
      enable_ops_center = false
    }
  }

  # Compute Dashboard
  assert {
    condition     = aws_cloudwatch_dashboard.compute.dashboard_name == "my-app-my-env-compute"
    error_message = "dashboard_name is incorrect"
  }

#  assert {
#    condition     = aws_cloudwatch_dashboard.compute.dashboard_name == "my-app-my-env-compute"
#    error_message = "dashboard_name is incorrect"
#  }
}
