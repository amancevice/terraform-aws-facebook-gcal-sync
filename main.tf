provider aws {
  profile = "bdsa"
  region  = "us-east-1"
  version = "~> 1.51"
}

data aws_iam_policy_document assume_role {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [
        "events.amazonaws.com",
        "lambda.amazonaws.com",
      ]
    }
  }
}

data aws_iam_policy_document inline {
  statement {
    sid       = "DecryptSecrets",
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [
      "${data.aws_secretsmanager_secret.facebook.arn}",
      "${data.aws_secretsmanager_secret.google.arn}",
    ]
  }

  statement {
    sid       = "InvokeLambdas",
    actions   = ["lambda:InvokeFunction"]
    resources = ["${aws_lambda_function.lambda.arn}"]
  }

  statement {
    sid       = "WriteLogs"
    actions   = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

data aws_secretsmanager_secret facebook {
  name = "${var.facebook_secret}"
}

data aws_secretsmanager_secret google {
  name = "${var.google_secret}"
}

resource aws_cloudwatch_event_rule rule {
  description         = "Sync facebook events with Google Calendar"
  is_enabled          = "${var.event_rule_is_enabled}"
  name                = "${aws_lambda_function.lambda.function_name}"
  role_arn            = "${aws_iam_role.role.arn}"
  schedule_expression = "${var.event_rule_schedule_expression}"
}

resource aws_cloudwatch_event_target target {
  count = "${var.create_event_target}"
  arn   = "${aws_lambda_function.lambda.arn}"
  input = "${var.event_target_input}"
  rule  = "${aws_cloudwatch_event_rule.rule.name}"
}

resource aws_cloudwatch_log_group logs {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  retention_in_days = "${var.log_group_retention_in_days}"
}

resource aws_iam_role role {
  description        = "Access to facebook, Google, and AWS resources."
  name               = "${var.lambda_function_name}"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource aws_iam_role_policy inline {
  name   = "${aws_iam_role.role.name}"
  policy = "${data.aws_iam_policy_document.inline.json}"
  role   = "${aws_iam_role.role.name}"
}

resource aws_lambda_function lambda {
  description      = "Synchronize facebook page events with Google Calendar"
  filename         = "${path.module}/package.zip"
  function_name    = "${var.lambda_function_name}"
  handler          = "lambda.handler"
  role             = "${aws_iam_role.role.arn}"
  runtime          = "python3.7"
  source_code_hash = "${base64sha256(file("${path.module}/package.zip"))}"
  timeout          = 30

  environment {
    variables {
      FACEBOOK_PAGE_ID   = "${var.facebook_page_id}"
      FACEBOOK_SECRET    = "${data.aws_secretsmanager_secret.facebook.name}"
      GOOGLE_CALENDAR_ID = "${var.google_calendar_id}"
      GOOGLE_SECRET      = "${data.aws_secretsmanager_secret.google.name}"
    }
  }
}

resource aws_lambda_permission trigger {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.rule.arn}"
}
