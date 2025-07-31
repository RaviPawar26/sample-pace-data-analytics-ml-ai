// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_kms_key" "s3_kms_key" {

  key_id   = "alias/${var.S3_KMS_KEY_ALIAS}"
}

module "z_etl_db_data_bucket" {

  source = "../../../../templates/modules/bucket"
  
  APP       = var.APP
  ENV       = var.ENV
  NAME      = "equity-order-dd-zetl-s3-data"
  USAGE     = "zetl-ddb"
  CMK_ARN   = data.aws_kms_key.s3_kms_key.arn
}

resource "aws_s3_object" "equity_orders_data" {
  
  bucket = module.z_etl_db_data_bucket.bucket_id
  key = "equity_orders.csv.gz"
  source = "${path.module}/../../../../../data/equity_orders/equity_orders.csv.gz"
}