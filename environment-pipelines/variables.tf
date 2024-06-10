variable "application" {
  type = string
}

variable "repository" {
  type = string
}

variable "pipeline_name" {
  type = string
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

variable "branch" {
  type    = string
  default = "main"
}

variable "slack_channel" {
  type    = string
  default = "/codebuild/slack_pipeline_notifications_channel"
}
