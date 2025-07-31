// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# CloudWatch Log Group for EC2 instance system logs
resource "aws_cloudwatch_log_group" "ec2_system_logs" {
  name              = "/aws/ec2/${var.APP}-${var.ENV}-system"
  retention_in_days = 30

  provider = aws.primary

  tags = {
    Name        = "${var.APP}-${var.ENV}-ec2-system-logs"
    Environment = var.ENV
    Application = var.APP
    Component   = "ec2-monitoring"
  }
}

# CloudWatch Log Group for Streamlit application logs
resource "aws_cloudwatch_log_group" "streamlit_app_logs" {
  name              = "/aws/ec2/${var.APP}-${var.ENV}-streamlit"
  retention_in_days = 30

  provider = aws.primary

  tags = {
    Name        = "${var.APP}-${var.ENV}-streamlit-app-logs"
    Environment = var.ENV
    Application = var.APP
    Component   = "streamlit-monitoring"
  }
}

# CloudWatch Log Group for Docker container logs
resource "aws_cloudwatch_log_group" "docker_logs" {
  name              = "/aws/ec2/${var.APP}-${var.ENV}-docker"
  retention_in_days = 14

  provider = aws.primary

  tags = {
    Name        = "${var.APP}-${var.ENV}-docker-logs"
    Environment = var.ENV
    Application = var.APP
    Component   = "docker-monitoring"
  }
}

# CloudWatch Log Group for user data script logs
resource "aws_cloudwatch_log_group" "user_data_logs" {
  name              = "/aws/ec2/${var.APP}-${var.ENV}-user-data"
  retention_in_days = 7

  provider = aws.primary

  tags = {
    Name        = "${var.APP}-${var.ENV}-user-data-logs"
    Environment = var.ENV
    Application = var.APP
    Component   = "ec2-bootstrap"
  }
}

# CloudWatch Log Group for custom metrics logs
resource "aws_cloudwatch_log_group" "custom_metrics_logs" {
  name              = "/aws/ec2/${var.APP}-${var.ENV}-custom-metrics"
  retention_in_days = 14

  provider = aws.primary

  tags = {
    Name        = "${var.APP}-${var.ENV}-custom-metrics-logs"
    Environment = var.ENV
    Application = var.APP
    Component   = "custom-monitoring"
  }
}

# CloudWatch metric alarm for EC2 CPU utilization
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_utilization" {
  alarm_name          = "${var.APP}-${var.ENV}-ec2-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors EC2 CPU utilization"
  alarm_actions       = []

  dimensions = {
    InstanceId = aws_instance.streamlit_host.id
  }

  provider = aws.primary

  tags = {
    Name        = "${var.APP}-${var.ENV}-ec2-cpu-alarm"
    Environment = var.ENV
    Application = var.APP
    Component   = "ec2-monitoring"
  }
}

# CloudWatch metric alarm for EC2 memory utilization (requires CloudWatch agent)
resource "aws_cloudwatch_metric_alarm" "ec2_memory_utilization" {
  alarm_name          = "${var.APP}-${var.ENV}-ec2-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "This metric monitors EC2 memory utilization"
  alarm_actions       = []

  dimensions = {
    InstanceId = aws_instance.streamlit_host.id
  }

  provider = aws.primary

  tags = {
    Name        = "${var.APP}-${var.ENV}-ec2-memory-alarm"
    Environment = var.ENV
    Application = var.APP
    Component   = "ec2-monitoring"
  }
}

# CloudWatch metric alarm for EC2 disk utilization
resource "aws_cloudwatch_metric_alarm" "ec2_disk_utilization" {
  alarm_name          = "${var.APP}-${var.ENV}-ec2-disk-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DiskSpaceUtilization"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors EC2 disk utilization"
  alarm_actions       = []

  dimensions = {
    InstanceId = aws_instance.streamlit_host.id
    device     = "/dev/xvda1"
    fstype     = "xfs"
    path       = "/"
  }

  provider = aws.primary

  tags = {
    Name        = "${var.APP}-${var.ENV}-ec2-disk-alarm"
    Environment = var.ENV
    Application = var.APP
    Component   = "ec2-monitoring"
  }
}

# CloudWatch metric alarm for Lambda memory utilization
resource "aws_cloudwatch_metric_alarm" "lambda_memory_utilization" {
  alarm_name          = "${var.APP}-${var.ENV}-lambda-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"
  alarm_description   = "This metric monitors Lambda memory utilization"
  alarm_actions       = []

  dimensions = {
    FunctionName = aws_lambda_function.spark_code_interpreter.function_name
  }

  provider = aws.primary

  tags = {
    Name        = "${var.APP}-${var.ENV}-lambda-memory-alarm"
    Environment = var.ENV
    Application = var.APP
    Component   = "lambda-monitoring"
  }
}

# CloudWatch metric alarm for Lambda throttles
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "${var.APP}-${var.ENV}-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors Lambda throttles"
  alarm_actions       = []

  dimensions = {
    FunctionName = aws_lambda_function.spark_code_interpreter.function_name
  }

  provider = aws.primary

  tags = {
    Name        = "${var.APP}-${var.ENV}-lambda-throttles-alarm"
    Environment = var.ENV
    Application = var.APP
    Component   = "lambda-monitoring"
  }
}

# CloudWatch metric alarm for Lambda concurrent executions
resource "aws_cloudwatch_metric_alarm" "lambda_concurrent_executions" {
  alarm_name          = "${var.APP}-${var.ENV}-lambda-concurrent-executions"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ConcurrentExecutions"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "50"
  alarm_description   = "This metric monitors Lambda concurrent executions"
  alarm_actions       = []

  dimensions = {
    FunctionName = aws_lambda_function.spark_code_interpreter.function_name
  }

  provider = aws.primary

  tags = {
    Name        = "${var.APP}-${var.ENV}-lambda-concurrency-alarm"
    Environment = var.ENV
    Application = var.APP
    Component   = "lambda-monitoring"
  }
}

# Custom CloudWatch metric for Streamlit application health
resource "aws_cloudwatch_log_metric_filter" "streamlit_error_count" {
  name           = "${var.APP}-${var.ENV}-streamlit-errors"
  log_group_name = aws_cloudwatch_log_group.streamlit_app_logs.name
  pattern        = "[timestamp, request_id, ERROR]"

  metric_transformation {
    name      = "StreamlitErrorCount"
    namespace = "Custom/${var.APP}/${var.ENV}"
    value     = "1"
  }

  provider = aws.primary
}

# CloudWatch alarm for Streamlit application errors
resource "aws_cloudwatch_metric_alarm" "streamlit_error_rate" {
  alarm_name          = "${var.APP}-${var.ENV}-streamlit-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StreamlitErrorCount"
  namespace           = "Custom/${var.APP}/${var.ENV}"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors Streamlit application error rate"
  alarm_actions       = []
  treat_missing_data  = "notBreaching"

  provider = aws.primary

  tags = {
    Name        = "${var.APP}-${var.ENV}-streamlit-error-alarm"
    Environment = var.ENV
    Application = var.APP
    Component   = "streamlit-monitoring"
  }
}

# Custom CloudWatch metric for Docker container restarts
resource "aws_cloudwatch_log_metric_filter" "docker_restart_count" {
  name           = "${var.APP}-${var.ENV}-docker-restarts"
  log_group_name = aws_cloudwatch_log_group.docker_logs.name
  pattern        = "[timestamp, level=\"INFO\", message=\"Container*restarted\"]"

  metric_transformation {
    name      = "DockerRestartCount"
    namespace = "Custom/${var.APP}/${var.ENV}"
    value     = "1"
  }

  provider = aws.primary
}

# CloudWatch alarm for Docker container restarts
resource "aws_cloudwatch_metric_alarm" "docker_restart_rate" {
  alarm_name          = "${var.APP}-${var.ENV}-docker-restart-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DockerRestartCount"
  namespace           = "Custom/${var.APP}/${var.ENV}"
  period              = "300"
  statistic           = "Sum"
  threshold           = "3"
  alarm_description   = "This metric monitors Docker container restart frequency"
  alarm_actions       = []
  treat_missing_data  = "notBreaching"

  provider = aws.primary

  tags = {
    Name        = "${var.APP}-${var.ENV}-docker-restart-alarm"
    Environment = var.ENV
    Application = var.APP
    Component   = "docker-monitoring"
  }
}

# CloudWatch Dashboard for monitoring overview
resource "aws_cloudwatch_dashboard" "spark_code_interpreter_dashboard" {
  dashboard_name = "${var.APP}-${var.ENV}-spark-code-interpreter"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.spark_code_interpreter.function_name],
            [".", "Errors", ".", "."],
            [".", "Invocations", ".", "."],
            [".", "Throttles", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.AWS_PRIMARY_REGION
          title   = "Lambda Function Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.streamlit_host.id],
            ["CWAgent", "MemoryUtilization", "InstanceId", aws_instance.streamlit_host.id],
            [".", "DiskSpaceUtilization", "InstanceId", aws_instance.streamlit_host.id, "device", "/dev/xvda1", "fstype", "xfs", "path", "/"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.AWS_PRIMARY_REGION
          title   = "EC2 Instance Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["Custom/${var.APP}/${var.ENV}", "StreamlitErrorCount"],
            [".", "DockerRestartCount"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.AWS_PRIMARY_REGION
          title   = "Application Health Metrics"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          query  = "SOURCE '${aws_cloudwatch_log_group.spark_lambda_logs.name}' | fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20"
          region = var.AWS_PRIMARY_REGION
          title  = "Recent Lambda Errors"
          view   = "table"
        }
      }
    ]
  })

  provider = aws.primary
}

# Custom CloudWatch metric for Streamlit container health
resource "aws_cloudwatch_log_metric_filter" "streamlit_container_health" {
  name           = "${var.APP}-${var.ENV}-streamlit-container-health"
  log_group_name = aws_cloudwatch_log_group.ec2_system_logs.name
  pattern        = "[timestamp, level, message=\"Container*restarted\"]"

  metric_transformation {
    name      = "StreamlitContainerRestarts"
    namespace = "Custom/${var.APP}/${var.ENV}"
    value     = "1"
  }

  provider = aws.primary
}

# CloudWatch alarm for Streamlit container health
resource "aws_cloudwatch_metric_alarm" "streamlit_container_health" {
  alarm_name          = "${var.APP}-${var.ENV}-streamlit-container-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "StreamlitContainerHealth"
  namespace           = "Custom/${var.APP}/${var.ENV}"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors Streamlit container health status"
  alarm_actions       = []
  treat_missing_data  = "breaching"

  dimensions = {
    InstanceId = aws_instance.streamlit_host.id
  }

  provider = aws.primary

  tags = {
    Name        = "${var.APP}-${var.ENV}-streamlit-health-alarm"
    Environment = var.ENV
    Application = var.APP
    Component   = "streamlit-monitoring"
  }
}

# CloudWatch alarm for Lambda cold starts
resource "aws_cloudwatch_metric_alarm" "lambda_cold_starts" {
  alarm_name          = "${var.APP}-${var.ENV}-lambda-cold-starts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "30000" # 30 seconds
  alarm_description   = "This metric monitors Lambda cold start duration"
  alarm_actions       = []

  dimensions = {
    FunctionName = aws_lambda_function.spark_code_interpreter.function_name
  }

  provider = aws.primary

  tags = {
    Name        = "${var.APP}-${var.ENV}-lambda-cold-start-alarm"
    Environment = var.ENV
    Application = var.APP
    Component   = "lambda-monitoring"
  }
}

# CloudWatch Log Insights saved queries for troubleshooting
resource "aws_cloudwatch_query_definition" "lambda_errors_query" {
  name = "${var.APP}-${var.ENV}-lambda-errors"

  log_group_names = [
    aws_cloudwatch_log_group.spark_lambda_logs.name
  ]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
EOF

  provider = aws.primary
}

resource "aws_cloudwatch_query_definition" "streamlit_performance_query" {
  name = "${var.APP}-${var.ENV}-streamlit-performance"

  log_group_names = [
    aws_cloudwatch_log_group.streamlit_app_logs.name
  ]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /response_time/ or @message like /memory_usage/
| sort @timestamp desc
| limit 50
EOF

  provider = aws.primary
}

resource "aws_cloudwatch_query_definition" "docker_container_issues" {
  name = "${var.APP}-${var.ENV}-docker-issues"

  log_group_names = [
    aws_cloudwatch_log_group.docker_logs.name,
    aws_cloudwatch_log_group.ec2_system_logs.name
  ]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /docker/ and (@message like /error/ or @message like /failed/ or @message like /restart/)
| sort @timestamp desc
| limit 50
EOF

  provider = aws.primary
}
