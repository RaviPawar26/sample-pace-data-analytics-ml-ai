// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# ECR Repository outputs for Spark Lambda Handler
output "spark_lambda_handler_repository_url" {
  description = "URL of the ECR repository for Spark Lambda Handler"
  value       = aws_ecr_repository.spark_lambda_handler.repository_url
}

output "spark_lambda_handler_repository_arn" {
  description = "ARN of the ECR repository for Spark Lambda Handler"
  value       = aws_ecr_repository.spark_lambda_handler.arn
}

output "spark_lambda_handler_registry_id" {
  description = "Registry ID of the ECR repository for Spark Lambda Handler"
  value       = aws_ecr_repository.spark_lambda_handler.registry_id
}

# ECR Repository outputs for Streamlit Application
output "streamlit_app_repository_url" {
  description = "URL of the ECR repository for Streamlit Application"
  value       = aws_ecr_repository.streamlit_app.repository_url
}

output "streamlit_app_repository_arn" {
  description = "ARN of the ECR repository for Streamlit Application"
  value       = aws_ecr_repository.streamlit_app.arn
}

output "streamlit_app_registry_id" {
  description = "Registry ID of the ECR repository for Streamlit Application"
  value       = aws_ecr_repository.streamlit_app.registry_id
}

# Docker Image URI outputs
output "spark_lambda_image_uri" {
  description = "Full URI of the Spark Lambda Handler Docker image"
  value       = null_resource.spark_lambda_docker_build.triggers.image_uri
  depends_on  = [null_resource.spark_lambda_docker_build]
}

output "streamlit_app_image_uri" {
  description = "Full URI of the Streamlit Application Docker image"
  value       = null_resource.streamlit_app_docker_build.triggers.image_uri
  depends_on  = [null_resource.streamlit_app_docker_build]
}
# IAM Role outputs
output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "lambda_execution_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda_execution_role.name
}

output "ec2_instance_role_arn" {
  description = "ARN of the EC2 instance role"
  value       = aws_iam_role.ec2_instance_role.arn
}

output "ec2_instance_role_name" {
  description = "Name of the EC2 instance role"
  value       = aws_iam_role.ec2_instance_role.name
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_instance_profile.name
}

output "ec2_instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_instance_profile.arn
}

# Lambda Function outputs
output "lambda_function_name" {
  description = "Name of the Spark Code Interpreter Lambda function"
  value       = aws_lambda_function.spark_code_interpreter.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Spark Code Interpreter Lambda function"
  value       = aws_lambda_function.spark_code_interpreter.arn
}

output "lambda_function_invoke_arn" {
  description = "Invoke ARN of the Spark Code Interpreter Lambda function"
  value       = aws_lambda_function.spark_code_interpreter.invoke_arn
}

output "lambda_function_version" {
  description = "Version of the Spark Code Interpreter Lambda function"
  value       = aws_lambda_function.spark_code_interpreter.version
}

output "lambda_alias_arn" {
  description = "ARN of the Lambda function alias"
  value       = aws_lambda_alias.spark_code_interpreter_live.arn
}

output "lambda_dlq_arn" {
  description = "ARN of the Lambda dead letter queue"
  value       = aws_sqs_queue.spark_lambda_dlq.arn
}

output "lambda_dlq_url" {
  description = "URL of the Lambda dead letter queue"
  value       = aws_sqs_queue.spark_lambda_dlq.url
}

output "lambda_log_group_name" {
  description = "Name of the Lambda CloudWatch log group"
  value       = aws_cloudwatch_log_group.spark_lambda_logs.name
}

output "lambda_log_group_arn" {
  description = "ARN of the Lambda CloudWatch log group"
  value       = aws_cloudwatch_log_group.spark_lambda_logs.arn
}

# Security Group outputs
output "lambda_security_group_id" {
  description = "ID of the Lambda function security group"
  value       = aws_security_group.lambda_sg.id
}

output "lambda_security_group_arn" {
  description = "ARN of the Lambda function security group"
  value       = aws_security_group.lambda_sg.arn
}

output "ec2_security_group_id" {
  description = "ID of the EC2 instance security group"
  value       = aws_security_group.ec2_streamlit_sg.id
}

output "ec2_security_group_arn" {
  description = "ARN of the EC2 instance security group"
  value       = aws_security_group.ec2_streamlit_sg.arn
}

# EC2 Instance outputs
output "ec2_instance_id" {
  description = "ID of the EC2 instance hosting Streamlit"
  value       = aws_instance.streamlit_host.id
}

output "ec2_instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.streamlit_host.public_ip
}

output "ec2_instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.streamlit_host.private_ip
}

output "streamlit_application_url" {
  description = "URL to access the Streamlit application"
  value       = "http://${aws_instance.streamlit_host.public_ip}:8501"
}

# Monitoring and Logging outputs
output "cloudwatch_dashboard_url" {
  description = "URL to access the CloudWatch dashboard"
  value       = "https://${var.AWS_PRIMARY_REGION}.console.aws.amazon.com/cloudwatch/home?region=${var.AWS_PRIMARY_REGION}#dashboards:name=${var.APP}-${var.ENV}-spark-code-interpreter"
}

output "ec2_log_groups" {
  description = "CloudWatch log groups for EC2 monitoring"
  value = {
    system_logs    = aws_cloudwatch_log_group.ec2_system_logs.name
    streamlit_logs = aws_cloudwatch_log_group.streamlit_app_logs.name
    docker_logs    = aws_cloudwatch_log_group.docker_logs.name
    user_data_logs = aws_cloudwatch_log_group.user_data_logs.name
  }
}

output "monitoring_alarms" {
  description = "CloudWatch alarms for monitoring"
  value = {
    lambda_errors                = aws_cloudwatch_metric_alarm.spark_lambda_errors.alarm_name
    lambda_duration             = aws_cloudwatch_metric_alarm.spark_lambda_duration.alarm_name
    lambda_memory               = aws_cloudwatch_metric_alarm.lambda_memory_utilization.alarm_name
    lambda_throttles            = aws_cloudwatch_metric_alarm.lambda_throttles.alarm_name
    lambda_concurrent_executions = aws_cloudwatch_metric_alarm.lambda_concurrent_executions.alarm_name
    lambda_cold_starts          = aws_cloudwatch_metric_alarm.lambda_cold_starts.alarm_name
    ec2_cpu                     = aws_cloudwatch_metric_alarm.ec2_cpu_utilization.alarm_name
    ec2_memory                  = aws_cloudwatch_metric_alarm.ec2_memory_utilization.alarm_name
    ec2_disk                    = aws_cloudwatch_metric_alarm.ec2_disk_utilization.alarm_name
    streamlit_errors            = aws_cloudwatch_metric_alarm.streamlit_error_rate.alarm_name
    streamlit_container_health  = aws_cloudwatch_metric_alarm.streamlit_container_health.alarm_name
    docker_restarts             = aws_cloudwatch_metric_alarm.docker_restart_rate.alarm_name
  }
}

output "log_insights_queries" {
  description = "CloudWatch Log Insights saved queries"
  value = {
    lambda_errors_query         = aws_cloudwatch_query_definition.lambda_errors_query.name
    streamlit_performance_query = aws_cloudwatch_query_definition.streamlit_performance_query.name
    docker_container_issues     = aws_cloudwatch_query_definition.docker_container_issues.name
  }
}