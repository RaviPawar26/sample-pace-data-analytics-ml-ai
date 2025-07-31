// Copyright 2024 Amazon.com and its affiliates; all rights reserved.
// This file is Amazon Web Services Content and may not be duplicated or distributed without permission.

module "data_trade_hive_bucket" {

  source = "../../../templates/modules/bucket"

  APP       = var.APP
  ENV       = var.ENV
  NAME      = "equity-trade-msk-glue-s3-hive"
  USAGE     = "equity-trade"
  CMK_ARN   = data.aws_kms_key.s3_kms_key.arn
}

module "data_trade_iceberg_bucket" {

  source = "../../../templates/modules/bucket"

  APP       = var.APP
  ENV       = var.ENV
  NAME      = "equity-trade-msk-glue-s3-iceberg"
  USAGE     = "equity-trade"
  CMK_ARN   = data.aws_kms_key.s3_kms_key.arn
}

resource "aws_lakeformation_resource" "hive_s3_location" {

  arn       = "arn:aws:s3:::${var.AWS_ACCOUNT_ID}-${var.APP}-${var.ENV}-equity-trade-msk-glue-s3-hive"
  role_arn  = data.aws_iam_role.glue_role.arn

  use_service_linked_role     = false
  hybrid_access_enabled       = true

  depends_on = [ module.data_trade_iceberg_bucket ]
}

resource "aws_lakeformation_permissions" "trade_deployer_role" {

  principal   = local.role_arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = aws_lakeformation_resource.hive_s3_location.arn
  }
}

resource "aws_lakeformation_permissions" "trade_glue_role" {

  principal   = data.aws_iam_role.glue_role.arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = aws_lakeformation_resource.hive_s3_location.arn
  }
}

resource "aws_lakeformation_resource" "iceberg_s3_location" {

  arn       = "arn:aws:s3:::${var.AWS_ACCOUNT_ID}-${var.APP}-${var.ENV}-equity-trade-msk-glue-s3-iceberg"
  role_arn  = data.aws_iam_role.glue_role.arn

  use_service_linked_role     = false
  hybrid_access_enabled       = true

  depends_on = [ module.data_trade_iceberg_bucket ]
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