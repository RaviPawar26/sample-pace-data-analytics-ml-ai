// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_kms_key" "s3_kms_key" {

  key_id   = "alias/${var.S3_KMS_KEY_ALIAS}"
}

module "equity_order_zetl_ddb_bucket" {

  source = "../../../../templates/modules/bucket"
  
  APP       = var.APP
  ENV       = var.ENV
  NAME      = "equity-order-dd-zetl-s3"
  USAGE     = "zetl-ddb"
  CMK_ARN   = data.aws_kms_key.s3_kms_key.arn
}