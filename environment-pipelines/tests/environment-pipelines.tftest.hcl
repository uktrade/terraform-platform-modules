run "test_create_pipelines" {
  command = plan

  variables {
    application = "my-app"
  }

  assert {
    condition     = aws_iam_role.environment_pipeline_role.name == "my-app-environment-pipeline-role"
    error_message = "Invalid value for aws_iam_role.environment_pipeline_role.name parameter, should be: 'my-app-environment-pipeline-role'"
  }
}

run "test_create_pipelines_with_different_application" {
  command = plan

  variables {
    application = "my-other-app"
  }

  assert {
    condition     = aws_iam_role.environment_pipeline_role.name == "my-other-app-environment-pipeline-role"
    error_message = "Invalid value for aws_iam_role.environment_pipeline_role.name parameter, should be: 'my-other-app-environment-pipeline-role'"
  }
}
