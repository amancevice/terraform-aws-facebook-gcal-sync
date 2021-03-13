output "event_rule" {
  description = "CloudWatch Event Rule"
  value       = aws_cloudwatch_event_rule.rule
}

output "facebook_secret" {
  description = "facebook SecretsManager secret"
  value       = aws_secretsmanager_secret.facebook_secret
}

output "google_secret" {
  description = "Google service account SecretsManager secret"
  value       = aws_secretsmanager_secret.google_secret
}

output "iam_role" {
  description = "Lambda IAM role"
  value       = aws_iam_role.role
}

output "lambda_function" {
  description = "Lambda function"
  value       = aws_lambda_function.lambda
}
