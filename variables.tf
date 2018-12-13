variable facebook_page_id {
  description = "facebook Page ID."
}

variable facebook_secret {
  description = "facebook SecretsManager secret name."
}

variable google_calendar_id {
  description = "Google Calendar ID."
}

variable google_secret {
  description = "Google SecretsManager secret name."
}

variable lambda_function_name {
  description = "Lambda function name."
  default     = "facebook-gcal-sync"
}

variable log_group_retention_in_days {
  description = "CloudWatch Log Group retention period in days."
  default     = 30
}

variable event_rule_is_enabled {
  description = "Flag to enable/disable CloudWatch Event Rule."
  default     = true
}

variable event_rule_schedule_expression {
  description = "CloudWatch event rule schedule expression"
  default     = "rate(1 hour)"
}
