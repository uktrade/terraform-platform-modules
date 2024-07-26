variable "application" {
  type = string
}

variable "all_pipelines" {
  type    = any
  default = {}
}

variable "branch" {
  type    = string
  default = "main"
}

variable "environments" {
  type = map(
    object(
      {
        vpc               = optional(string)
        requires_approval = optional(bool)
      }
    )
  )
}

variable "environment_config" {
  type = any
}


variable "pipeline_name" {
  type = string
}

variable "pipeline_that_gets_triggered" {
  type = string
}


variable "repository" {
  type = string
}

variable "slack_channel" {
  type    = string
  default = "/codebuild/slack_pipeline_notifications_channel"
}
# variable "triggered_by_pipeline" {
#   type = string
# }

variable "trigger_on_push" {
  type    = bool
  default = true
}

