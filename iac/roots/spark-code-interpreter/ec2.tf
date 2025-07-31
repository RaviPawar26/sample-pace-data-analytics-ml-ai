// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# Data source to get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 instance for hosting Streamlit application
resource "aws_instance" "streamlit_host" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.large"
  vpc_security_group_ids = [aws_security_group.ec2_streamlit_sg.id]
  subnet_id              = data.aws_subnets.public.ids[0]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  # EBS volume configuration
  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true

    tags = {
      Name        = "${var.APP}-${var.ENV}-streamlit-host-root-volume"
      Application = var.APP
      Environment = var.ENV
    }
  }

  # User data script for container deployment
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    AWS_REGION          = var.AWS_PRIMARY_REGION
    ECR_REGISTRY        = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.AWS_PRIMARY_REGION}.amazonaws.com"
    STREAMLIT_IMAGE_URI = "${aws_ecr_repository.streamlit_app.repository_url}:latest"
    APP                 = var.APP
    ENV                 = var.ENV
    AWS_ACCOUNT_ID      = data.aws_caller_identity.current.account_id
  }))

  # Force instance replacement when user data changes
  user_data_replace_on_change = true

  tags = {
    Name        = "${var.APP}-${var.ENV}-streamlit-host"
    Application = var.APP
    Environment = var.ENV
    Component   = "streamlit-host"
  }

  lifecycle {
    create_before_destroy = true
  }
}
