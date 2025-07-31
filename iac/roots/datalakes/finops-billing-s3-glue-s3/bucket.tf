// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_kms_key" "s3_kms_key" {

  key_id   = "alias/${var.S3_KMS_KEY_ALIAS}"
}

module "billing_data_bucket" {

  source = "../../../templates/modules/bucket"
  
  APP       = var.APP
  ENV       = var.ENV
  NAME      = "finops-billing-s3-glue-s3-data"
  USAGE     = "billing"
  CMK_ARN   = data.aws_kms_key.s3_kms_key.arn
}

data "aws_iam_policy_document" "billing_policy_document" {

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["billingreports.amazonaws.com"]
    }
    actions = [
      "s3:GetBucketAcl",
      "s3:GetBucketPolicy"
    ]
    resources = [module.billing_data_bucket.bucket_arn]
  }

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["billingreports.amazonaws.com"]
    }
    actions = ["s3:PutObject"]
    resources = ["${module.billing_data_bucket.bucket_arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "billing_policy" {

  bucket = module.billing_data_bucket.bucket_id
  policy = data.aws_iam_policy_document.billing_policy_document.json
}

resource "aws_s3_bucket_notification" "billing_s3_notification" {

  bucket = module.billing_data_bucket.bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.billing_workflow_trigger.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "billing/"
    filter_suffix       = ".gz"
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}

module "billing_hive_bucket" {

  source = "../../../templates/modules/bucket"
  
  APP       = var.APP
  ENV       = var.ENV
  NAME      = "finops-billing-s3-glue-s3-hive"
  USAGE     = "billing"
  CMK_ARN   = data.aws_kms_key.s3_kms_key.arn
}

module "billing_iceberg_bucket" {

  source = "../../../templates/modules/bucket"
  
  APP       = var.APP
  ENV       = var.ENV
  NAME      = "finops-billing-s3-glue-s3-iceberg"
  USAGE     = "billing"
  CMK_ARN   = data.aws_kms_key.s3_kms_key.arn
}

resource "aws_s3_object" "billing_data_files" {

  for_each = fileset("${path.module}/../../../../data/billing/static/", "*.gz")
  bucket   = module.billing_data_bucket.bucket_id
  key = each.value
  source = "${path.module}/../../../../data/billing/static/${each.value}"
  content_type = "gz"
  kms_key_id = data.aws_kms_key.s3_kms_key.arn
}

resource "aws_lakeformation_resource" "hive_s3_location" {

  arn       = "arn:aws:s3:::${var.AWS_ACCOUNT_ID}-${var.APP}-${var.ENV}-finops-billing-s3-glue-s3-hive"
  role_arn  = data.aws_iam_role.glue_role.arn

  use_service_linked_role     = false
  hybrid_access_enabled       = true

  depends_on = [ module.billing_hive_bucket ]
}

resource "aws_lakeformation_permissions" "hive_deployer_role" {

  principal   = local.role_arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = aws_lakeformation_resource.hive_s3_location.arn
  }
}

resource "aws_lakeformation_permissions" "hive_glue_role" {

  principal   = data.aws_iam_role.glue_role.arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = aws_lakeformation_resource.hive_s3_location.arn
  }
}

resource "aws_lakeformation_resource" "iceberg_s3_location" {

  arn       = "arn:aws:s3:::${var.AWS_ACCOUNT_ID}-${var.APP}-${var.ENV}-finops-billing-s3-glue-s3-iceberg"
  role_arn  = data.aws_iam_role.glue_role.arn

  use_service_linked_role     = false
  hybrid_access_enabled       = true

  depends_on = [ module.billing_iceberg_bucket ]
}

resource "aws_lakeformation_permissions" "iceberg_deployer_role" {

  principal   = local.role_arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = aws_lakeformation_resource.iceberg_s3_location.arn
  }
}

resource "aws_lakeformation_permissions" "iceberg_glue_role" {

  principal   = data.aws_iam_role.glue_role.arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = aws_lakeformation_resource.iceberg_s3_location.arn
  }
}