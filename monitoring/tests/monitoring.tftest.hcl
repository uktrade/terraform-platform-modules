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

  # Compute Dashboard
  assert {
    condition     = aws_cloudwatch_dashboard.compute.dashboard_name == "test-application-test-environment-compute"
    error_message = "dashboard_name is incorrect"
  }
  assert {
    condition     = aws_cloudwatch_dashboard.compute.dashboard_body == "test-application-test-environment-compute"
    error_message = "dashboard_name is incorrect"
  }

#  # module.backing-services-tf.module.monitoring["demodjango-tf-monitoring"].aws_cloudwatch_dashboard.compute will be created
#  + resource "aws_cloudwatch_dashboard" "compute" {
#      + dashboard_arn  = (known after apply)
#      + dashboard_body = jsonencode(
#            {
#              + widgets = [
#                  + {
#                      + height     = 7
#                      + properties = {
#                          + query   = <<-EOT
#                                SOURCE '/aws/ecs/containerinsights/demodjango-tf-tf-will/performance' | fields @message
#                                | filter Type="Task"
#                                | filter @logStream like /FargateTelemetry/
#                                | stats latest(TaskDefinitionFamily) as TaskDefFamily,
#                                        latest(TaskDefinitionRevision) as Rev,
#                                        max(CpuReserved) as TaskCpuReserved,
#                                        avg(CpuUtilized) as AvgCpuUtilized,
#                                        concat(ceil(avg(CpuUtilized) * 100 / TaskCpuReserved)," %") as AvgCpuUtilizedPerc,
#                                        max(CpuUtilized) as PeakCpuUtilized,
#                                        concat(ceil(max(CpuUtilized) * 100 / TaskCpuReserved)," %") as PeakCpuUtilizedPerc,
#                                        max(MemoryReserved) as TaskMemReserved,
#                                        ceil(avg(MemoryUtilized)) as AvgMemUtilized,
#                                        concat(ceil(avg(MemoryUtilized) * 100 / TaskMemReserved)," %") as AvgMemUtilizedPerc,
#                                        max(MemoryUtilized) as PeakMemUtilized,
#                                        concat(ceil(max(MemoryUtilized) * 100 / TaskMemReserved)," %") as PeakMemUtilizedPerc
#                                        by TaskId
#                                | sort TaskDefFamily asc
#                            EOT
#                          + region  = "eu-west-2"
#                          + stacked = false
#                          + title   = "All Fargate Tasks Configuration and Consumption Details (CPU and Memory)"
#                          + view    = "table"
#                        }
#                      + type       = "log"
#                      + width      = 24
#                      + x          = 0
#                      + y          = 0
#                    },
#                  + {
#                      + height     = 6
#                      + properties = {
#                          + query   = <<-EOT
#                                SOURCE '/aws/ecs/containerinsights/demodjango-tf-tf-will/performance' | fields @message
#                                | filter Type="Task"
#                                | filter @logStream like /FargateTelemetry/
#                                | stats latest(TaskDefinitionFamily) as TaskDefFamily, latest(ServiceName) as SvcName, concat(floor((max(CpuReserved) - avg(CpuUtilized)) * 100 / max(CpuReserved)), " %") as AvgCpuWastePercentage by TaskId
#                                | sort AvgCpuWastePercentage desc
#                                | limit 10
#                            EOT
#                          + stacked = false
#                          + title   = "Top 10 Fargate Tasks with Optimization Opportunities (CPU)"
#                          + view    = "table"
#                        }
#                      + type       = "log"
#                      + width      = 15
#                      + x          = 0
#                      + y          = 7
#                    },
#                  + {
#                      + height     = 6
#                      + properties = {
#                          + query   = <<-EOT
#                                SOURCE '/aws/ecs/containerinsights/demodjango-tf-tf-will/performance' | fields @message
#                                | filter Type="Task"
#                                | filter @logStream like /FargateTelemetry/
#                                | stats latest(TaskDefinitionFamily) as TaskDefFamily, latest(ServiceName) as SvcName, concat(floor((max(MemoryReserved) - avg(MemoryUtilized)) * 100 / max(MemoryReserved)), " %") as AvgMemWastePercentage by TaskId
#                                | sort AvgMemWastePercentage desc
#                                | limit 10
#                            EOT
#                          + stacked = false
#                          + title   = "Top 10 Fargate Tasks with Optimization Opportunities (Memory)"
#                          + view    = "table"
#                        }
#                      + type       = "log"
#                      + width      = 15
#                      + x          = 0
#                      + y          = 13
#                    },
#                  + {
#                      + height     = 6
#                      + properties = {
#                          + query   = <<-EOT
#                                SOURCE '/aws/ecs/containerinsights/demodjango-tf-tf-will/performance' | fields @message
#                                | filter Type = "Task"
#                                | filter @logStream like /FargateTelemetry/
#                                | stats count_distinct(TaskId) as TotalTasks, avg(CpuReserved) * TotalTasks as TotalCPUReserved, avg(CpuUtilized) * TotalTasks as AvgCPUConsumed by bin(15m)
#                            EOT
#                          + region  = "eu-west-2"
#                          + stacked = false
#                          + title   = "CPU Reserved Vs Avg Usage (All Fargate Tasks)"
#                          + view    = "timeSeries"
#                        }
#                      + type       = "log"
#                      + width      = 9
#                      + x          = 15
#                      + y          = 7
#                    },
#                  + {
#                      + height     = 6
#                      + properties = {
#                          + query   = <<-EOT
#                                SOURCE '/aws/ecs/containerinsights/demodjango-tf-tf-will/performance' | fields @message
#                                | filter Type = "Task"
#                                | filter @logStream like /FargateTelemetry/
#                                | stats count_distinct(TaskId) as TotalTasks, avg(MemoryReserved) * TotalTasks as TotalMemReserved, avg(MemoryUtilized) * TotalTasks as AvgMemConsumed by bin(30m)
#                            EOT
#                          + stacked = false
#                          + title   = "Memory Reserved Vs Avg Usage (All Fargate Tasks)"
#                          + view    = "timeSeries"
#                        }
#                      + type       = "log"
#                      + width      = 9
#                      + x          = 15
#                      + y          = 13
#                    },
#                ]
#            }
#        )
#      + dashboard_name = "demodjango-tf-tf-will-compute"
#      + id             = (known after apply)
#    }
#
#
  # Application Insights
#
#  # module.backing-services-tf.module.monitoring["demodjango-tf-monitoring"].aws_resourcegroups_group.application-insights-resources will be created
#  + resource "aws_resourcegroups_group" "application-insights-resources" {
#      + arn      = (known after apply)
#      + id       = (known after apply)
#      + name     = "demodjango-tf-tf-will-application-insights-resources"
#      + tags_all = (known after apply)
#
#      + resource_query {
#          + query = jsonencode(
#                {
#                  + ResourceTypeFilters = [
#                      + "AWS::AllSupported",
#                    ]
#                  + TagFilters          = [
#                      + {
#                          + Key    = "copilot-application"
#                          + Values = [
#                              + "demodjango-tf",
#                            ]
#                        },
#                      + {
#                          + Key    = "copilot-environment"
#                          + Values = [
#                              + "tf-will",
#                            ]
#                        },
#                    ]
#                }
#            )
#          + type  = "TAG_FILTERS_1_0"
#        }
#    }
#
## module.backing-services-tf.module.monitoring["demodjango-tf-monitoring"].aws_applicationinsights_application.application-insights will be created
#+ resource "aws_applicationinsights_application" "application-insights" {
#+ arn                 = (known after apply)
#+ auto_config_enabled = true
#+ id                  = (known after apply)
#+ ops_center_enabled  = false
#+ resource_group_name = "demodjango-tf-tf-will-application-insights-resources"
#+ tags_all            = (known after apply)
#}
#}

