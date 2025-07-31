// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# ECR Repository for Spark Lambda Handler
resource "aws_ecr_repository" "spark_lambda_handler" {
  name                 = "${var.APP}-${var.ENV}-spark-lambda-handler"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  provider = aws.primary

  tags = {
    Name        = "${var.APP}-${var.ENV}-spark-lambda-handler"
    Environment = var.ENV
    Application = var.APP
    Component   = "spark-lambda-handler"
  }
}

# ECR Repository for Streamlit Application
resource "aws_ecr_repository" "streamlit_app" {
  name                 = "${var.APP}-${var.ENV}-streamlit-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  provider = aws.primary

  tags = {
    Name        = "${var.APP}-${var.ENV}-streamlit-app"
    Environment = var.ENV
    Application = var.APP
    Component   = "streamlit-app"
  }
}

# Lifecycle policy for Spark Lambda Handler ECR repository
resource "aws_ecr_lifecycle_policy" "spark_lambda_handler_policy" {
  repository = aws_ecr_repository.spark_lambda_handler.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 30 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  provider = aws.primary
}

# Lifecycle policy for Streamlit Application ECR repository
resource "aws_ecr_lifecycle_policy" "streamlit_app_policy" {
  repository = aws_ecr_repository.streamlit_app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 30 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  provider = aws.primary
}

# Data source to get current AWS account ID and region
data "aws_caller_identity" "current" {
  provider = aws.primary
}

data "aws_region" "current" {
  provider = aws.primary
}

# Local values for image tags and build context
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  spark_lambda_image_tag  = "latest"
  streamlit_app_image_tag = "latest"

  spark_lambda_image_uri  = "${aws_ecr_repository.spark_lambda_handler.repository_url}:${local.spark_lambda_image_tag}"
  streamlit_app_image_uri = "${aws_ecr_repository.streamlit_app.repository_url}:${local.streamlit_app_image_tag}"
}

# Build and push Spark Lambda Handler Docker image
resource "null_resource" "spark_lambda_docker_build" {
  depends_on = [aws_ecr_repository.spark_lambda_handler]

  triggers = {
    dockerfile_hash   = filemd5("${path.module}/spark-on-lambda-handler/Dockerfile")
    requirements_hash = filemd5("${path.module}/spark-on-lambda-handler/requirements.txt")
    handler_hash      = filemd5("${path.module}/spark-on-lambda-handler/sparkLambdaHandler.py")
    download_jars_hash = filemd5("${path.module}/spark-on-lambda-handler/download_jars.sh")
    spark_class_hash  = filemd5("${path.module}/spark-on-lambda-handler/spark-class")
    repository_url    = aws_ecr_repository.spark_lambda_handler.repository_url
    image_uri         = "${aws_ecr_repository.spark_lambda_handler.repository_url}:${local.spark_lambda_image_tag}"
    account_id        = local.account_id
    region            = local.region
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Login to ECR
      aws ecr get-login-password --region ${self.triggers.region} | docker login --username AWS --password-stdin ${self.triggers.account_id}.dkr.ecr.${self.triggers.region}.amazonaws.com
      
            # Build Docker image for Spark Lambda Handler
      docker buildx build \
        --build-arg AWS_REGION=${self.triggers.region} \
        --build-arg FRAMEWORK="SPARK" \
        --platform linux/amd64 \
        --no-cache \
        --load \
        -t ${self.triggers.image_uri} \
        ${path.module}/spark-on-lambda-handler/
      
      # Push image to ECR
      docker push ${self.triggers.image_uri}
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      # Clean up local Docker image on destroy
      docker rmi ${self.triggers.image_uri} || true
    EOT
  }
}

# Build and push Streamlit Application Docker image
resource "null_resource" "streamlit_app_docker_build" {
  depends_on = [aws_ecr_repository.streamlit_app]

  triggers = {
    dockerfile_hash     = filemd5("${path.module}/streamlit-app/Dockerfile")
    requirements_hash   = filemd5("${path.module}/streamlit-app/requirements.txt")
    bedrock_chat_hash   = filemd5("${path.module}/streamlit-app/bedrock-chat.py")
    function_utils_hash = filemd5("${path.module}/streamlit-app/function_calling_utils.py")
    pricing_hash        = filemd5("${path.module}/streamlit-app/pricing.json")
    config_hash         = filemd5("${path.module}/streamlit-app/config.json")
    entry_point_hash    = filemd5("${path.module}/streamlit-app/entrypoint.sh")
    repository_url      = aws_ecr_repository.streamlit_app.repository_url
    image_uri           = "${aws_ecr_repository.streamlit_app.repository_url}:${local.streamlit_app_image_tag}"
    account_id          = local.account_id
    region              = local.region
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Login to ECR
      aws ecr get-login-password --region ${self.triggers.region} | docker login --username AWS --password-stdin ${self.triggers.account_id}.dkr.ecr.${self.triggers.region}.amazonaws.com
      
      # Build Docker image for Streamlit Application
      docker buildx build \
        --platform linux/amd64 \
        --no-cache \
        --load \
        -t ${self.triggers.image_uri} \
        ${path.module}/streamlit-app/
      
      # Push image to ECR
      docker push ${self.triggers.image_uri}
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      # Clean up local Docker image on destroy
      docker rmi ${self.triggers.image_uri} || true
    EOT
  }
}
