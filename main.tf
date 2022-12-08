#################
#   TERRAFORM   #
#################

terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

##############
#   LOCALS   #
##############

locals {
  event_target = {
    input = var.event_target_input
  }

  event_rule = {
    is_enabled          = var.event_rule_is_enabled
    schedule_expression = var.event_rule_schedule_expression
  }

  facebook_secret = {
    description = var.facebook_secret_description
    name        = var.facebook_secret_name
    tags        = var.facebook_secret_tags
  }

  google_secret = {
    description = var.google_secret_description
    name        = var.google_secret_name
    tags        = var.google_secret_tags
  }

  kms_key = {
    alias                   = var.kms_key_alias
    deletion_window_in_days = var.kms_key_deletion_window_in_days
    description             = var.kms_key_description
    enable_key_rotation     = var.kms_key_enable_key_rotation
    is_enabled              = var.kms_key_is_enabled
    policy_document         = var.kms_key_policy_document
    tags                    = var.kms_key_tags
    usage                   = var.kms_key_usage
  }

  lambda = {
    description   = var.lambda_description
    filename      = "${path.module}/src/package.zip"
    function_name = var.lambda_function_name
    runtime       = var.lambda_runtime
    timeout       = var.lambda_timeout

    environment_variables = {
      FACEBOOK_PAGE_ID   = var.facebook_page_id
      FACEBOOK_SECRET    = aws_secretsmanager_secret.facebook_secret.name
      GOOGLE_CALENDAR_ID = var.google_calendar_id
      GOOGLE_SECRET      = aws_secretsmanager_secret.google_secret.name
      PYTHONPATH         = "/var/task/python"
    }
  }

  log_group = {
    retention_in_days = var.log_group_retention_in_days
  }
}

###################
#   EVENTBRIDGE   #
###################

resource "aws_cloudwatch_event_rule" "rule" {
  description         = "Sync facebook events with Google Calendar"
  is_enabled          = local.event_rule.is_enabled
  name                = aws_lambda_function.lambda.function_name
  role_arn            = aws_iam_role.role.arn
  schedule_expression = local.event_rule.schedule_expression
}

resource "aws_cloudwatch_event_target" "target" {
  arn   = aws_lambda_function.lambda.arn
  input = jsonencode(local.event_target.input)
  rule  = aws_cloudwatch_event_rule.rule.name
}

##########################
#   LAMBDA :: FUNCTION   #
##########################

resource "aws_lambda_function" "lambda" {
  description      = local.lambda.description
  filename         = local.lambda.filename
  function_name    = local.lambda.function_name
  handler          = "index.handler"
  role             = aws_iam_role.role.arn
  runtime          = local.lambda.runtime
  source_code_hash = filebase64sha256(local.lambda.filename)
  timeout          = local.lambda.timeout

  environment {
    variables = local.lambda.environment_variables
  }
}

resource "aws_lambda_permission" "trigger" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rule.arn
}

#####################
#   LAMBDA :: IAM   #
#####################

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "events.amazonaws.com",
        "lambda.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "inline" {
  statement {
    sid     = "DecryptSecrets"
    actions = ["secretsmanager:GetSecretValue"]

    resources = [
      aws_secretsmanager_secret.facebook_secret.arn,
      aws_secretsmanager_secret.google_secret.arn,
    ]
  }

  statement {
    sid       = "InvokeLambdas"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.lambda.arn]
  }

  statement {
    sid       = "WriteLogs"
    resources = ["*"]

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
  }
}

resource "aws_iam_role" "role" {
  description        = "Access to facebook, Google, and AWS resources."
  name               = local.lambda.function_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "inline" {
  name   = aws_iam_role.role.name
  policy = data.aws_iam_policy_document.inline.json
  role   = aws_iam_role.role.name
}

######################
#   LAMBDA :: LOGS   #
######################

resource "aws_cloudwatch_log_group" "logs" {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  retention_in_days = local.log_group.retention_in_days
}

###############
#   SECRETS   #
###############

resource "aws_kms_key" "key" {
  deletion_window_in_days = local.kms_key.deletion_window_in_days
  description             = local.kms_key.description
  enable_key_rotation     = local.kms_key.enable_key_rotation
  is_enabled              = local.kms_key.is_enabled
  key_usage               = local.kms_key.usage
  policy                  = local.kms_key.policy_document
  tags                    = local.kms_key.tags
}

resource "aws_kms_alias" "alias" {
  name          = local.kms_key.alias
  target_key_id = aws_kms_key.key.key_id
}

resource "aws_secretsmanager_secret" "facebook_secret" {
  description = local.facebook_secret.description
  kms_key_id  = aws_kms_key.key.key_id
  name        = local.facebook_secret.name
  tags        = local.facebook_secret.tags
}

resource "aws_secretsmanager_secret" "google_secret" {
  description = local.google_secret.description
  kms_key_id  = aws_kms_key.key.key_id
  name        = local.google_secret.name
  tags        = local.google_secret.tags
}
