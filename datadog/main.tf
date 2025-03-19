

resource "datadog_software_catalog" "system_v3" {
  provider = datadog.dd
  entity = <<EOF
apiVersion: v3
kind: system
metadata:
  name: ${var.application}
  displayName: ${var.application}-system
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
#${var.config.team_name}