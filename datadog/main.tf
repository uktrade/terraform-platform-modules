// Create the System (parent) component in DataDog Software Catalog
resource "datadog_software_catalog" "system_v3" {
  provider = datadog.ddog
  entity = <<EOF
apiVersion: v3
kind: system
metadata:
  name: ${var.application}
  displayName: ${var.application}
  links:
    - name: ${var.application}
      type: repo
      url: ${var.config.repository}
  contacts:
    - name: ${var.config.contact_name}
      type: email
      contact: ${var.config.contact_email}
  owner: ${var.config.team_name}
EOF
}

// Create the Service (child) component in DataDog Software Catalog
resource "datadog_software_catalog" "service_v3" {
  provider = datadog.ddog
  for_each = toset(var.config.services_to_monitor)
  entity = <<EOF
apiVersion: v3
kind: service
metadata:
  tags:
    - application:demodjango
  name: ${each.value}
  displayName: ${var.application}:${each.value}
  links:
    - name: ${var.application}
      type: repo
      url: ${var.config.repository}
    - name: readme
      type: doc
      url: ${var.config.docs}
  contacts:
    - name: ${var.config.contact_name}
      type: email
      contact: ${var.config.contact_email}
  owner: ${var.config.team_name}
spec:
  lifecycle: production
  tier: "1"
  type: web
  componentOf: 
    - system:${var.application}
  languages:
    - python
datadog:
  pipelines:
    fingerprints:
      - SheHsDihoccN
EOF
}
