// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# S3 buckets for Spark Code Interpreter application

# Get KMS keys for bucket encryption
data "aws_kms_key" "s3_kms_key" {

  key_id = "alias/aws/s3"
  provider = aws.primary
}

# Operations bucket for document uploads and Textract results
module "operations_bucket" {

  source = "../../templates/modules/bucket"

  APP       = var.APP
  ENV       = var.ENV
  NAME      = "bedrock-operations"
  USAGE     = "genai"
  CMK_ARN   = data.aws_kms_key.s3_kms_key.arn
}

# Data bucket for input files
module "data_bucket" {
  source = "../../templates/modules/bucket"

  APP       = var.APP
  ENV       = var.ENV
  NAME      = "bedrock-data"
  USAGE     = "genai"
  CMK_ARN   = data.aws_kms_key.s3_kms_key.arn
}

# Create the required folders in the operations bucket
resource "aws_s3_object" "document_upload_cache" {

  bucket  = "${var.AWS_ACCOUNT_ID}-${var.APP}-${var.ENV}-bedrock-operations"
  key     = "document-upload-cache/${var.APP}-${var.ENV}/"
  content_type = "application/x-directory"
  content = ""
  provider = aws.primary

  depends_on = [module.operations_bucket]
}

resource "aws_s3_object" "textract_result_cache" {

  bucket  = "${var.AWS_ACCOUNT_ID}-${var.APP}-${var.ENV}-bedrock-operations"
  key     = "amazon-textract-result-cache/"
  content_type = "application/x-directory"
  content = ""
  provider = aws.primary

  depends_on = [module.operations_bucket]
}

# Create the required folders in the data bucket
resource "aws_s3_object" "demo_folder" {

  bucket  = "${var.AWS_ACCOUNT_ID}-${var.APP}-${var.ENV}-bedrock-data"
  key     = "${var.APP}-${var.ENV}/"
  content_type = "application/x-directory"
  content = ""
  provider = aws.primary

  depends_on = [module.data_bucket]
}

# Output the bucket names
output "operations_bucket_name" {

  description = "Name of the operations S3 bucket"
  value       = "${var.AWS_ACCOUNT_ID}-${var.APP}-${var.ENV}-bedrock-operations"
}

output "data_bucket_name" {
  
  description = "Name of the data S3 bucket"
  value       = "${var.AWS_ACCOUNT_ID}-${var.APP}-${var.ENV}-bedrock-data"
}