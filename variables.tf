variable "event_rule_is_enabled" {
  description = "Flag to enable/disable CloudWatch event rule"
  default     = true
}

variable "event_rule_schedule_expression" {
  description = "CloudWatch event rule schedule expression"
  default     = "rate(1 hour)"
}

variable "event_target_input" {
  description = "CloudWatch event target input JSON"
  type        = map(string)
  default     = {}
}

variable "facebook_page_id" {
  description = "facebook Page ID"
}

variable "facebook_secret_description" {
  description = "facebook SecretsManager Secret description"
  default     = "facebook app token"
}

variable "facebook_secret_name" {
  description = "facebook SecretsManager secret name"
}

variable "facebook_secret_tags" {
  description = "facebook SecretsManager Secret resource tags"
  type        = map(string)
  default     = {}
}

variable "google_calendar_id" {
  description = "Google Calendar ID"
}

variable "google_secret_description" {
  description = "Google SecretsManager secret description"
  default     = "Google service account credentials"
}

variable "google_secret_name" {
  description = "Google service account SecretsManager secret name"
}

variable "google_secret_tags" {
  description = "Google service account SecretsManager secret tags"
  type        = map(string)
  default     = {}
}

variable "kms_key_alias" {
  description = "KMS Key alias"
  default     = "facebook-gcal-sync"
}

variable "kms_key_deletion_window_in_days" {
  description = "KMS Key deletion window"
  default     = 30
}

variable "kms_key_enable_key_rotation" {
  description = "KMS Key rotation flag"
  default     = false
}

variable "kms_key_is_enabled" {
  description = "KMS Key enabled flag"
  default     = true
}

variable "kms_key_description" {
  description = "KMS Key description"
  default     = "Slackbot key"
}

variable "kms_key_policy_document" {
  description = "KMS Key policy JSON document"
  default     = null
}

variable "kms_key_tags" {
  description = "KMS Key resource tags"
  type        = map(string)
  default     = {}
}

variable "kms_key_usage" {
  description = "KMS Key usage"
  default     = "ENCRYPT_DECRYPT"
}

variable "lambda_description" {
  description = "Lambda function description"
  default     = "Synchronize facebook page events with Google Calendar"
}

variable "lambda_function_name" {
  description = "Lambda function name"
  default     = "facebook-gcal-sync"
}

variable "lambda_runtime" {
  description = "Lambda function runtime"
  default     = "python3.8"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  default     = 30
}

variable "log_group_retention_in_days" {
  description = "CloudWatch Log Group retention period in days"
  default     = 30
}
