// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# Data source to get VPC information
data "aws_vpc" "main" {
  id = data.aws_ssm_parameter.vpc_id.value
}

# Data source to get public subnets for EC2 instance
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_ssm_parameter.vpc_id.value]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.APP}-${var.ENV}-public-subnet-*"]
  }
}

# Data source to get current public IP address
data "external" "my_ip" {
  program = ["bash", "-c", "echo '{\"ip\":\"'$(curl -s https://checkip.amazonaws.com)'/32\"}'"]
}

# Security Group for Lambda function
resource "aws_security_group" "lambda_sg" {
  name_prefix = "${var.APP}-${var.ENV}-lambda-spark-"
  description = "Security group for Spark Code Interpreter Lambda function"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    description = "Lambda VPC access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  # Outbound rules for Lambda function
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.APP}-${var.ENV}-lambda-spark-sg"
    Application = var.APP
    Environment = var.ENV
    Component   = "lambda"
  }
}

# Add specific rule for Lambda to access VPC endpoints
# This is redundant with the "Allow all outbound traffic" rule above,
# but explicitly documents the dependency on VPC endpoints
resource "aws_security_group_rule" "lambda_to_vpc_endpoints" {
  security_group_id = aws_security_group.lambda_sg.id
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  # Reference the VPC CIDR block since we can't directly reference the VPC endpoint security group
  # from another module
  cidr_blocks = [data.aws_vpc.main.cidr_block]
  description = "Allow Lambda to access VPC endpoints"
}

# Security Group for EC2 instance hosting Streamlit
resource "aws_security_group" "ec2_streamlit_sg" {
  name_prefix = "${var.APP}-${var.ENV}-ec2-streamlit-"
  description = "Security group for EC2 instance hosting Streamlit application"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  # Inbound rules for EC2 instance - restricted to your IP and Lambda
  ingress {
    description = "HTTP inbound for Streamlit application from your IP only"
    from_port   = 8501
    to_port     = 8501
    protocol    = "tcp"
    cidr_blocks = [data.external.my_ip.result.ip]
  }

  # Outbound rules for EC2 instance
  egress {
    description = "HTTPS outbound for AWS API calls and ECR"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP outbound for package downloads"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.APP}-${var.ENV}-ec2-streamlit-sg"
    Application = var.APP
    Environment = var.ENV
    Component   = "ec2-streamlit"
  }
}
