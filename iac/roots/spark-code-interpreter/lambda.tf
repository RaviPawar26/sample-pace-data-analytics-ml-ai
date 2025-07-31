// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# Data source to get VPC ID from SSM Parameter Store
data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.APP}/${var.ENV}/vpc_id"
}

# Data source to get private subnets for Lambda VPC configuration
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_ssm_parameter.vpc_id.value]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.APP}-${var.ENV}-private-subnet-*"]
  }
}

# CloudWatch Log Group for Lambda function
resource "aws_cloudwatch_log_group" "spark_lambda_logs" {
  name              = "/aws/lambda/${var.APP}-${var.ENV}-spark-code-interpreter"
  retention_in_days = 14

  provider = aws.primary

  tags = {
    Name        = "${var.APP}-${var.ENV}-spark-lambda-logs"
    Environment = var.ENV
    Application = var.APP
    Component   = "spark-lambda"
  }
}

# SQS Dead Letter Queue for Lambda error handling
resource "aws_sqs_queue" "spark_lambda_dlq" {
  name                      = "${var.APP}-${var.ENV}-spark-lambda-dlq"
  message_retention_seconds = 1209600 # 14 days

  provider = aws.primary

  tags = {
    Name        = "${var.APP}-${var.ENV}-spark-lambda-dlq"
    Environment = var.ENV
    Application = var.APP
    Component   = "spark-lambda"
  }
}

# Lambda function using container image
resource "aws_lambda_function" "spark_code_interpreter" {
  depends_on = [
    null_resource.spark_lambda_docker_build,
    aws_cloudwatch_log_group.spark_lambda_logs
  ]

  function_name = "${var.APP}-${var.ENV}-spark-code-interpreter"
  description   = "Lambda function that execute spark code job using Spark on Lambda container image"
  role          = aws_iam_role.lambda_execution_role.arn
  package_type  = "Image"
  image_uri     = local.spark_lambda_image_uri

  # Memory and timeout configuration
  memory_size = 1024
  ephemeral_storage {
    size = 1024
  }
  timeout = 900

  # Environment variables for Spark configuration
  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }

  # Dead letter queue configuration
  dead_letter_config {
    target_arn = aws_sqs_queue.spark_lambda_dlq.arn
  }

  # VPC configuration for Lambda function
  vpc_config {
    subnet_ids         = data.aws_subnets.private.ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  # Reserved concurrency to prevent overwhelming downstream services
  # Note: reserved_concurrency is configured separately if needed

  provider = aws.primary

  tags = {
    Name        = "${var.APP}-${var.ENV}-spark-code-interpreter"
    Environment = var.ENV
    Application = var.APP
    Component   = "spark-lambda"
  }
}

# Lambda function alias for versioning
resource "aws_lambda_alias" "spark_code_interpreter_live" {
  name             = "live"
  description      = "Live alias for Spark Code Interpreter Lambda function"
  function_name    = aws_lambda_function.spark_code_interpreter.function_name
  function_version = "$LATEST"

  provider = aws.primary
}

# CloudWatch metric alarm for Lambda errors
resource "aws_cloudwatch_metric_alarm" "spark_lambda_errors" {
  alarm_name          = "${var.APP}-${var.ENV}-spark-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors lambda errors"
  alarm_actions       = []

  dimensions = {
    FunctionName = aws_lambda_function.spark_code_interpreter.function_name
  }

  provider = aws.primary

  tags = {
    Name        = "${var.APP}-${var.ENV}-spark-lambda-errors"
    Environment = var.ENV
    Application = var.APP
    Component   = "spark-lambda"
  }
}

# CloudWatch metric alarm for Lambda duration
resource "aws_cloudwatch_metric_alarm" "spark_lambda_duration" {
  alarm_name          = "${var.APP}-${var.ENV}-spark-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "800000" # 800 seconds (close to 900s timeout)
  alarm_description   = "This metric monitors lambda duration approaching timeout"
  alarm_actions       = []

  dimensions = {
    FunctionName = aws_lambda_function.spark_code_interpreter.function_name
  }

  provider = aws.primary

  tags = {
    Name        = "${var.APP}-${var.ENV}-spark-lambda-duration"
    Environment = var.ENV
    Application = var.APP
    Component   = "spark-lambda"
  }
}
