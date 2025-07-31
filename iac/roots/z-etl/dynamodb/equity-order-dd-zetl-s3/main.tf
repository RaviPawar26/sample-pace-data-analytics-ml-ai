// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_kms_key" "dynamodb_primary_key" {

  key_id   = "alias/${var.DYNAMODB_PRIMARY_KMS_KEY_ALIAS}"
}

data "aws_kms_key" "glue_kms_key" {

  key_id   = "alias/${var.GLUE_PRIMARY_KMS_KEY_ALIAS}"
}

data "aws_iam_policy_document" "z_etl_ddb_policy_document" {

  statement {
    sid = "AllowDynamoDBExport"
    effect = "Allow"
    resources = [ module.dynamodb_table.arn, "${module.dynamodb_table.arn}/export/*" ]
    actions = [
      "dynamodb:ExportTableToPointInTime",
      "dynamodb:DescribeTable",
      "dynamodb:DescribeExport"
      ]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:glue:*:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}

data "archive_file" "zetl_integration_lambda_zip" {

  type        = "zip"
  source_file = "${path.module}/../../create_zetl_integration.py"
  output_path = "${path.module}/ddb_zetl_integration.zip"
}

# Create DynamoDB table using existing module
module "dynamodb_table" {

  source = "../../../../templates/modules/dynamodb"
  
  table_name     = var.Z_ETL_DYNAMODB_TABLE
  hash_key       = "order_id"
  range_key      = null
  stream_enabled = false
  
  attributes = [
    {
      name = "order_id"
      type = "S"
    }
  ]
  dynamodb_kms_key_arn = data.aws_kms_key.dynamodb_primary_key.arn
  # Import configuration
  enable_import             = true
  import_format             = "CSV"
  import_compression_type   = "GZIP"
  import_bucket_name        = var.Z_ETL_DYNAMODB_DATA_BUCKET
  csv_delimiter             = ","
  
  local_secondary_indices  = []
  global_secondary_indices = []
}

# Create IAM role for DynamoDB import
resource "aws_iam_role" "dynamodb_import_role" {

  name     = "${var.APP}-${var.ENV}-dynamodb-import-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "dynamodb.amazonaws.com"
      }
    }]
  })
}

# Create IAM policy for DynamoDB to access S3
resource "aws_iam_policy" "dynamodb_import_policy" {

  name     = "${var.APP}-${var.ENV}-dynamodb-import-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::${var.Z_ETL_DYNAMODB_DATA_BUCKET}",
          "arn:aws:s3:::${var.Z_ETL_DYNAMODB_DATA_BUCKET}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = [
          "*"
        ]
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "dynamodb_import_policy_attachment" {

  role       = aws_iam_role.dynamodb_import_role.name
  policy_arn = aws_iam_policy.dynamodb_import_policy.arn
}

resource "aws_dynamodb_resource_policy" "z_etl_ddb_resource_policy" {

  resource_arn = module.dynamodb_table.arn
  policy = data.aws_iam_policy_document.z_etl_ddb_policy_document.json
}


module "z-etl-integration-lambda" {

  region = var.AWS_PRIMARY_REGION
  source = "../../../../templates/modules/lambda"
  function_name     = "${var.APP}-${var.ENV}-z-etl-integration"
  handler_name      = "create_zetl_integration.lambda_handler"
  description       = "Create z-etl glue instance with dynamodb"
  runtime           = "python3.12"
  resource_policies = [aws_iam_policy.intergration_lambda_policy.arn]
  code_archive      = data.archive_file.zetl_integration_lambda_zip.output_path
  code_archive_hash = data.archive_file.zetl_integration_lambda_zip.output_base64sha256
  depends_on = [module.dynamodb_table]
}

resource "aws_lambda_invocation" "zetl_integration_invoke" {
  
  function_name = module.z-etl-integration-lambda.function_name
  qualifier = module.z-etl-integration-lambda.function_version
  triggers = {
    redeployment = sha1(jsonencode({
      sourceArn = module.dynamodb_table.arn
      targetArn = aws_glue_catalog_database.zetl_ddb_database.arn
    }))
  }
  input = jsonencode({
    app = var.APP
    env = var.ENV
    sourceArn = module.dynamodb_table.arn
    integrationName = "${var.APP}-${var.ENV}-ddb-glue-zetl-integration"
    targetArn = aws_glue_catalog_database.zetl_ddb_database.arn
    targetTableName = "equity_order_dd_zetl_s3_iceberg"
    targetRoleArn = aws_iam_role.aws_iam_glue_role.arn
    IntegrationkmsKeyArn= data.aws_kms_key.glue_kms_key.arn
    TargetkmsKeyArn = data.aws_kms_key.s3_kms_key.arn
  })
  lifecycle_scope = "CRUD"
}