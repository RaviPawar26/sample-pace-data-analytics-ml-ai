// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_kms_key" "glue_kms_key" {

  key_id   = "alias/${var.GLUE_KMS_KEY_ALIAS}"
}

data "aws_kms_key" "cloudwatch_kms_key" {

  key_id   = "alias/${var.CLOUDWATCH_KMS_KEY_ALIAS}"
}

resource "aws_s3_object" "trading_data_generator_script" {

  bucket     = data.aws_s3_bucket.glue_scripts_bucket.id
  key        = "trading_data_generator.py"
  source     = "${path.module}/src/lambda/trading_data_generator.py"
  kms_key_id = data.aws_kms_key.s3_primary_key.arn
}

resource "aws_glue_security_configuration" "glue_security_configuration" {

  name = "glue-security-configuration-equity-order-sf-zetl-fed"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "SSE-KMS"
      kms_key_arn                = data.aws_kms_key.cloudwatch_kms_key.arn
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "CSE-KMS"
      kms_key_arn                   = data.aws_kms_key.glue_kms_key.arn
    }

    s3_encryption {
      s3_encryption_mode = "SSE-KMS"
      kms_key_arn        = data.aws_kms_key.glue_kms_key.arn
    }
  }
}

resource "aws_glue_job" "trading_data_generator_job" {

  name              = "equity-order-sf-zetl-fed-data-generator"
  description       = "equity-order-sf-zetl-fed-data-generator"
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 10

  security_configuration = aws_glue_security_configuration.glue_security_configuration.name

  command {
    script_location = "s3://${var.GLUE_SCRIPTS_BUCKET_NAME}/trading_data_generator.py"
  }

  default_arguments = {
    "--enable-metrics"                   = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-job-insights"              = "true"
    "--enable-observability-metrics"     = "true"
    "--enable-spark-ui"                  = "true"
    "--job-language"                     = "python"
    "--TempDir"                          = var.GLUE_TEMP_BUCKET
    "--spark-event-logs-path"            = var.GLUE_SPARK_LOGS_BUCKET
    "--SNOWFLAKE_URL"                    = data.aws_ssm_parameter.snowflake_host.value
    "--SNOWFLAKE_DATABASE_NAME"          = data.aws_ssm_parameter.snowflake_database.value
    "--SNOWFLAKE_SCHEMA_NAME"            = data.aws_ssm_parameter.snowflake_schema.value
    "--SNOWFLAKE_WAREHOUSE_NAME"         = data.aws_ssm_parameter.snowflake_warehouse.value
    "--SNOWFLAKE_TABLE_NAME"             = var.SNOWFLAKE_TABLE_NAME
    "--SNOWFLAKE_SECRET_NAME"            = var.SNOWFLAKE_SECRET_NAME
  }
}
