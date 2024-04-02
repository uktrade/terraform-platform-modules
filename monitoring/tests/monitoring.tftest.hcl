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
    application = "my_app"
    environment = "my_env"
    vpc_name    = "terraform-tests-vpc"

    config = {
      enable_ops_center = false
    }
  }

  # Compute Dashboard
  assert {
    condition     = aws_cloudwatch_dashboard.compute.dashboard_name == "my_app-my_env-compute"
    error_message = "dashboard_name is incorrect"
  }
}
