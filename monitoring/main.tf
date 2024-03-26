data "aws_ecs_cluster" "ecs_cluster" {
  # Todo: get this programmatically
  cluster_name = "demodjango-tf-tf-will-Cluster-atiizAyfbYEq"
#  filter {
#    name   = "copilot-application"
#    values = [var.application]
#  }
#  filter {
#    name   = "copilot-environment"
#    values = [var.environment]
#  }
}

# Todo EnableOpsCenter: {% if config.enable_ops_center %}true{% else %}false{% endif %}

resource "aws_cloudwatch_dashboard" "compute" {
  dashboard_name = "${var.application}-${var.environment}-compute"

  dashboard_body = jsonencode({
    widgets : [
      {
        height : 7,
        width : 24,
        y : 0,
        x : 0,
        type : "log",
        properties : {
          query : "SOURCE '/aws/ecs/containerinsights/${data.aws_ecs_cluster.ecs_cluster.cluster_name}/performance' | fields @message\n| filter Type=\"Task\"\n| filter @logStream like /FargateTelemetry/\n| stats latest(TaskDefinitionFamily) as TaskDefFamily, \n        latest(TaskDefinitionRevision) as Rev, \n        max(CpuReserved) as TaskCpuReserved, \n        avg(CpuUtilized) as AvgCpuUtilized, \n        concat(ceil(avg(CpuUtilized) * 100 / TaskCpuReserved),\" %\") as AvgCpuUtilizedPerc, \n        max(CpuUtilized) as PeakCpuUtilized, \n        concat(ceil(max(CpuUtilized) * 100 / TaskCpuReserved),\" %\") as PeakCpuUtilizedPerc, \n        max(MemoryReserved) as TaskMemReserved, \n        ceil(avg(MemoryUtilized)) as AvgMemUtilized, \n        concat(ceil(avg(MemoryUtilized) * 100 / TaskMemReserved),\" %\") as AvgMemUtilizedPerc, \n        max(MemoryUtilized) as PeakMemUtilized, \n        concat(ceil(max(MemoryUtilized) * 100 / TaskMemReserved),\" %\") as PeakMemUtilizedPerc \n        by TaskId\n| sort TaskDefFamily asc\n",
          region : "eu-west-2",
          stacked : false,
          title : "All Fargate Tasks Configuration and Consumption Details (CPU and Memory)",
          view : "table"
        }
      },
      {
        height : 6,
        width : 15,
        y : 7,
        x : 0,
        type : "log",
        properties : {
          query : "SOURCE '/aws/ecs/containerinsights/${data.aws_ecs_cluster.ecs_cluster.cluster_name}/performance' | fields @message\n| filter Type=\"Task\"\n| filter @logStream like /FargateTelemetry/\n| stats latest(TaskDefinitionFamily) as TaskDefFamily, latest(ServiceName) as SvcName, concat(floor((max(CpuReserved) - avg(CpuUtilized)) * 100 / max(CpuReserved)), \" %\") as AvgCpuWastePercentage by TaskId\n| sort AvgCpuWastePercentage desc\n| limit 10",
          stacked : false,
          title : "Top 10 Fargate Tasks with Optimization Opportunities (CPU)",
          view : "table"
        }
      },
      {
        height : 6,
        width : 15,
        y : 13,
        x : 0,
        type : "log",
        properties : {
          query : "SOURCE '/aws/ecs/containerinsights/${data.aws_ecs_cluster.ecs_cluster.cluster_name}/performance' | fields @message\n| filter Type=\"Task\"\n| filter @logStream like /FargateTelemetry/\n| stats latest(TaskDefinitionFamily) as TaskDefFamily, latest(ServiceName) as SvcName, concat(floor((max(MemoryReserved) - avg(MemoryUtilized)) * 100 / max(MemoryReserved)), \" %\") as AvgMemWastePercentage by TaskId\n| sort AvgMemWastePercentage desc\n| limit 10",
          stacked : false,
          title : "Top 10 Fargate Tasks with Optimization Opportunities (Memory)",
          view : "table"
        }
      },
      {
        height : 6,
        width : 9,
        y : 7,
        x : 15,
        type : "log",
        properties : {
          query : "SOURCE '/aws/ecs/containerinsights/${data.aws_ecs_cluster.ecs_cluster.cluster_name}/performance' | fields @message\n| filter Type = \"Task\"\n| filter @logStream like /FargateTelemetry/\n| stats count_distinct(TaskId) as TotalTasks, avg(CpuReserved) * TotalTasks as TotalCPUReserved, avg(CpuUtilized) * TotalTasks as AvgCPUConsumed by bin(15m) \n",
          region : "eu-west-2",
          stacked : false,
          title : "CPU Reserved Vs Avg Usage (All Fargate Tasks)",
          view : "timeSeries"
        }
      },
      {
        height : 6,
        width : 9,
        y : 13,
        x : 15,
        type : "log",
        properties : {
          query : "SOURCE '/aws/ecs/containerinsights/${data.aws_ecs_cluster.ecs_cluster.cluster_name}/performance' | fields @message\n| filter Type = \"Task\"\n| filter @logStream like /FargateTelemetry/\n| stats count_distinct(TaskId) as TotalTasks, avg(MemoryReserved) * TotalTasks as TotalMemReserved, avg(MemoryUtilized) * TotalTasks as AvgMemConsumed by bin(30m) \n",
          stacked : false,
          title : "Memory Reserved Vs Avg Usage (All Fargate Tasks)",
          view : "timeSeries"
        }
      }
    ]
  })
}

#Resources:
#
#  {{ addon_config.prefix }}ResourceGroup:
#    Type: AWS::ResourceGroups::Group
#    Properties:
#      Name: !Sub "${App}-${Env}-group"
#      Description: !Sub "Resource group for ${App} in ${Env} environment."
#      ResourceQuery:
#        Type: TAG_FILTERS_1_0
#        Query:
#          TagFilters:
#            - Key: copilot-application
#              Values:
#                - !Sub "${App}"
#            - Key: copilot-environment
#              Values:
#                - !Sub "${Env}"
#
#  {{ addon_config.prefix }}ApplicationInsights:
#    Type: AWS::ApplicationInsights::Application
#    Properties:
#      AutoConfigurationEnabled: true
#      ResourceGroupName: !Ref {{ addon_config.prefix }}ResourceGroup
#      OpsCenterEnabled: !FindInMap [{{ addon_config.prefix }}EnvConfiguration, !Ref Env, EnableOpsCenter]
