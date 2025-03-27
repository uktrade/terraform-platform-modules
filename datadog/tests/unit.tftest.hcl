mock_provider "datadog" {
  alias = "ddog"
}

variables {
  application = "test-app"
  environment = "test-env"
  config = {
    team_name           = "test-team",
    contact_name        = "test-contact-name",
    contact_email       = "test-contact-email",
    documentation_url   = "test-docs",
    services_to_monitor = ["test-web", "test-postgres"] #, "test-redis", "test-elasticsearch"]
  }
}

run "datadog_system_entity_test" {
  command = plan
  assert {
    condition     = datadog_software_catalog.datadog-software-catalog-system.entity == "apiVersion: v3\nkind: system\nmetadata:\n  name: test-app\n  displayName: test-app\n  links:\n    - name: readme\n      type: doc\n      url: test-docs\n  contacts:\n    - name: test-contact-name\n      type: email\n      contact: test-contact-email\n  owner: test-team\n"
    error_message = "Should be: apiVersion: v3\nkind: system\nmetadata:\n  name: test-app\n  displayName: test-app\n  links:\n    - name: readme\n      type: doc\n      url: test-docs\n  contacts:\n    - name: test-contact-name\n      type: email\n      contact: test-contact-email\n  owner: test-team\n"
  }
}

run "datadog_service_entity_test" {
  command = plan
  assert {
    condition     = datadog_software_catalog.datadog-software-catalog-service["test-web"].entity == "apiVersion: v3\nkind: service\nmetadata:\n  name: test-web\n  displayName: test-app:test-web\n  links:\n    - name: readme\n      type: doc\n      url: test-docs\n  contacts:\n    - name: test-contact-name\n      type: email\n      contact: test-contact-email\n  owner: test-team\nspec:\n  lifecycle: production\n  tier: \"1\"\n  type: web\n  componentOf: \n    - system:test-app\n  languages:\n    - python\ndatadog:\n  pipelines:\n    fingerprints:\n      - SheHsDihoccN\n"
    error_message = "Should be: apiVersion: v3\nkind: service\nmetadata:\n  name: test-web\n  displayName: test-app:test-web\n  links:\n    - name: readme\n      type: doc\n      url: test-docs\n  contacts:\n    - name: test-contact-name\n      type: email\n      contact: test-contact-email\n  owner: test-team\nspec:\n  lifecycle: production\n  tier: \"1\"\n  type: web\n  componentOf: \n    - system:test-app\n  languages:\n    - python\ndatadog:\n  pipelines:\n    fingerprints:\n      - SheHsDihoccN\n"
  }
  assert {
    condition     = datadog_software_catalog.datadog-software-catalog-service["test-postgres"].entity == "apiVersion: v3\nkind: service\nmetadata:\n  name: test-postgres\n  displayName: test-app:test-postgres\n  links:\n    - name: readme\n      type: doc\n      url: test-docs\n  contacts:\n    - name: test-contact-name\n      type: email\n      contact: test-contact-email\n  owner: test-team\nspec:\n  lifecycle: production\n  tier: \"1\"\n  type: web\n  componentOf: \n    - system:test-app\n  languages:\n    - python\ndatadog:\n  pipelines:\n    fingerprints:\n      - SheHsDihoccN\n"
    error_message = "Should be: apiVersion: v3\nkind: service\nmetadata:\n  name: test-postgres\n  displayName: test-app:test-postgres\n  links:\n    - name: readme\n      type: doc\n      url: test-docs\n  contacts:\n    - name: test-contact-name\n      type: email\n      contact: test-contact-email\n  owner: test-team\nspec:\n  lifecycle: production\n  tier: \"1\"\n  type: web\n  componentOf: \n    - system:test-app\n  languages:\n    - python\ndatadog:\n  pipelines:\n    fingerprints:\n      - SheHsDihoccN\n"
  }
}
