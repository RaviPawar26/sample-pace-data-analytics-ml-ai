// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_kms_key" "s3_kms_key" {

  key_id   = "alias/${var.S3_KMS_KEY_ALIAS}"
}

module "price_data_bucket" {

  source = "../../../templates/modules/bucket"
  
  APP       = var.APP
  ENV       = var.ENV
  NAME      = "equity-price-s3-glue-s3-data"
  USAGE     = "equity-price"
  CMK_ARN   = data.aws_kms_key.s3_kms_key.arn
}

module "price_hive_bucket" {

  source = "../../../templates/modules/bucket"
  
  APP       = var.APP
  ENV       = var.ENV
  NAME      = "equity-price-s3-glue-s3-hive"
  USAGE     = "equity-price"
  CMK_ARN   = data.aws_kms_key.s3_kms_key.arn
}

module "price_iceberg_bucket" {

  source = "../../../templates/modules/bucket"
  
  APP       = var.APP
  ENV       = var.ENV
  NAME      = "equity-price-s3-glue-s3-iceberg"
  USAGE     = "equity-price"
  CMK_ARN   = data.aws_kms_key.s3_kms_key.arn
}

resource "aws_s3_object" "price_data_files" {

  for_each = fileset("${path.module}/../../../../data/price/", "*.csv")
  bucket   = module.price_data_bucket.bucket_id
  key = each.value
  source = "${path.module}/../../../../data/price/${each.value}"
  content_type = "csv"
  kms_key_id = data.aws_kms_key.s3_kms_key.arn
}

resource "aws_lakeformation_resource" "hive_s3_location" {

  arn       = "arn:aws:s3:::${var.AWS_ACCOUNT_ID}-${var.APP}-${var.ENV}-equity-price-s3-glue-s3-hive"
  role_arn  = data.aws_iam_role.glue_role.arn

  use_service_linked_role     = false
  hybrid_access_enabled       = true

  depends_on = [ module.price_hive_bucket ]
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

  arn       = "arn:aws:s3:::${var.AWS_ACCOUNT_ID}-${var.APP}-${var.ENV}-equity-price-s3-glue-s3-iceberg"
  role_arn  = data.aws_iam_role.glue_role.arn

  use_service_linked_role     = false
  hybrid_access_enabled       = true

  depends_on = [ module.price_iceberg_bucket ]
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