output "event_rule_arn" {
  description = "CloudWatch Event Rule ARN"
  value       = aws_cloudwatch_event_rule.rule.arn
}

output "event_rule_name" {
  description = "CloudWatch Event Rule name"
  value       = aws_cloudwatch_event_rule.rule.name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.lambda.arn
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.lambda.function_name
}

output "lambda_role_arn" {
  description = "Lambda role ARN"
  value       = aws_iam_role.role.arn
}

output "lambda_role_name" {
  description = "Lambda role name"
  value       = aws_iam_role.role.name
}
