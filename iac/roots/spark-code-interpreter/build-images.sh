#!/bin/bash

# Build and push Docker images for Spark Code Interpreter
# This script can be used for manual builds or CI/CD pipelines

set -e

# Configuration
AWS_REGION=${AWS_REGION:-us-east-1}
APP_NAME=${APP_NAME:-daivi}
ENV_NAME=${ENV_NAME:-ali2}

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# ECR repository URLs
SPARK_LAMBDA_REPO="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APP_NAME}-${ENV_NAME}-spark-lambda-handler"
STREAMLIT_APP_REPO="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APP_NAME}-${ENV_NAME}-streamlit-app"

echo "Building and pushing Docker images..."
echo "AWS Region: ${AWS_REGION}"
echo "Account ID: ${ACCOUNT_ID}"
echo "Spark Lambda Repository: ${SPARK_LAMBDA_REPO}"
echo "Streamlit App Repository: ${STREAMLIT_APP_REPO}"

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Build and push Spark Lambda Handler image
echo "Building Spark Lambda Handler image..."
docker buildx build \
  --build-arg AWS_REGION=${AWS_REGION} \
  --build-arg FRAMEWORK="SPARK" \
  --platform linux/amd64 \
  --load \
  -t ${SPARK_LAMBDA_REPO}:latest \
  ./spark-on-lambda-handler/

echo "Pushing Spark Lambda Handler image..."
docker push ${SPARK_LAMBDA_REPO}:latest

# Build and push Streamlit Application image
echo "Building Streamlit Application image..."
docker buildx build \
  --platform linux/amd64 \
  -t ${STREAMLIT_APP_REPO}:latest \
  --load \
  ./streamlit-app/

echo "Pushing Streamlit Application image..."
docker push ${STREAMLIT_APP_REPO}:latest

echo "Docker images built and pushed successfully!"
echo "Spark Lambda Handler: ${SPARK_LAMBDA_REPO}:latest"
echo "Streamlit Application: ${STREAMLIT_APP_REPO}:latest"