resource "aws_cloudwatch_event_rule" "main" {
  name                = var.cloudwatch_event_name
  schedule_expression = var.schedule_expression
  is_enabled          = var.is_enabled
  depends_on = [
    aws_lambda_function.force_redeploy_ecs_service
  ]
  tags = local.tags
}

resource "aws_cloudwatch_event_target" "main" {
  rule      = aws_cloudwatch_event_rule.main.name
  target_id = var.target_id
  arn       = aws_lambda_function.force_redeploy_ecs_service.arn
}

resource "aws_lambda_function" "force_redeploy_ecs_service" {
  function_name    = var.function_name
  filename         = var.filename
  runtime          = var.runtime
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = var.handler
  source_code_hash = filebase64sha256("${var.filename}")

  environment {
    variables = {
      CLUSTER_NAME = "${var.product}-${var.service}-${local.workspace}-cluster"
      SERVICE_NAME = "${var.product}-${var.service}-${local.workspace}"
    }
  }

  tags = local.tags

}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "lambda_execution_policy" {
  name = "lambda_execution_policy"
  role = aws_iam_role.lambda_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecs:UpdateService"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ecs:${var.region}:${lookup(var.aws_account_id, local.workspace)}:service/${var.product}-${var.service}-${local.workspace}-cluster/${var.product}-${var.service}-${local.workspace}"
      },
      {
        Action = [
          "logs:CreateLogGroup"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:${var.region}:${lookup(var.aws_account_id, local.workspace)}:*"
      },
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:${var.region}:${lookup(var.aws_account_id, local.workspace)}:log-group:/aws/lambda/${var.function_name}:*"
      },
      {
        Action = [
          "events:PutTargets",
          "events:PutRule"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:events:${var.region}:${lookup(var.aws_account_id, local.workspace)}:rule/${var.cloudwatch_event_name}"
      }
    ]
  })
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.force_redeploy_ecs_service.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.main.arn
}
