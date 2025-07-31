// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_kms_key" "s3_kms_key" {

  key_id   = "alias/${var.S3_KMS_KEY_ALIAS}"
}

module "inventory_source_bucket" {

  source = "../../../templates/modules/bucket"

  APP       = var.APP
  ENV       = var.ENV
  NAME      = "finops-inventory-s3-glue-s3-source"
  USAGE     = "inventory"
  CMK_ARN   = data.aws_kms_key.s3_kms_key.arn
}

module "inventory_target_bucket" {

  source = "../../../templates/modules/bucket"

  APP       = var.APP
  ENV       = var.ENV
  NAME      = "finops-inventory-s3-glue-s3-target"
  USAGE     = "inventory"
  CMK_ARN   = data.aws_kms_key.s3_kms_key.arn
}

module "inventory_hive_bucket" {

  source = "../../../templates/modules/bucket"

  APP       = var.APP
  ENV       = var.ENV
  NAME      = "finops-inventory-s3-glue-s3-hive"
  USAGE     = "inventory"
  CMK_ARN   = data.aws_kms_key.s3_kms_key.arn
}

module "inventory_iceberg_bucket" {

  source = "../../../templates/modules/bucket"

  APP       = var.APP
  ENV       = var.ENV
  NAME      = "finops-inventory-s3-glue-s3-iceberg"
  USAGE     = "inventory"
  CMK_ARN   = data.aws_kms_key.s3_kms_key.arn
}

resource "aws_s3_bucket_notification" "inventory_s3_notification" {

  bucket = module.inventory_target_bucket.bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.inventory_workflow_trigger.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "${var.AWS_ACCOUNT_ID}-${var.APP}-${var.ENV}-finops-inventory-s3-glue-s3-source/InventoryConfig/data/"
    filter_suffix       = ".gz"
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}

resource "aws_s3_object" "inventory_target_files" {

  for_each     = fileset("${path.module}/../../../../data/inventory/static/", "*.gz")
  bucket       = module.inventory_target_bucket.bucket_id
  key          = each.value
  source       = "${path.module}/../../../../data/inventory/static/${each.value}"
  content_type = "gz"
  kms_key_id   = data.aws_kms_key.s3_kms_key.arn
}

resource "aws_lakeformation_resource" "hive_s3_location" {

  arn       = "arn:aws:s3:::${var.AWS_ACCOUNT_ID}-${var.APP}-${var.ENV}-finops-inventory-s3-glue-s3-hive"
  role_arn  = data.aws_iam_role.glue_role.arn

  use_service_linked_role     = false
  hybrid_access_enabled       = false

  depends_on = [ module.inventory_hive_bucket ]
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

  arn       = "arn:aws:s3:::${var.AWS_ACCOUNT_ID}-${var.APP}-${var.ENV}-finops-inventory-s3-glue-s3-iceberg"
  role_arn  = data.aws_iam_role.glue_role.arn

  use_service_linked_role     = false
  hybrid_access_enabled       = false

  depends_on = [ module.inventory_iceberg_bucket ]
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