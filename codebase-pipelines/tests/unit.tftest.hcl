mock_provider "aws" {
  override_resource {
    target = aws_ecr_repository.demodjango_api
    values = {
      id = "demodjango/api"
    }
  }
}

run "data_migration_unit_test" {
  command = plan

  assert {
    condition     = aws_ecr_repository.demodjango_api.name == "demodjango/api"
    error_message = "Name should be: demodjango/api"
  }
}

