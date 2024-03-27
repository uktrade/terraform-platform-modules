# Terraform platform modules

## Monitoring

This will provision a CloudWatch Compute Dashboard and Application Insights for `<application>-<environment>`.

Example usage in `backing-services.yml`...

```yaml
demodjango-tf-monitoring:
  type: monitoring
  environments:
    "*":
      enable_ops_center: false
    prod:
      enable_ops_center: true
```
