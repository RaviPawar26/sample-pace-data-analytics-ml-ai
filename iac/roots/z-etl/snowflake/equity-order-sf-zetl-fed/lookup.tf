// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_ssm_parameter" "snowflake_host" {

  name     = "/${var.APP}/${var.ENV}/snowflake/host"
}

data "aws_ssm_parameter" "snowflake_port" {

  name     = "/${var.APP}/${var.ENV}/snowflake/port"
}

data "aws_ssm_parameter" "snowflake_warehouse" {

  name     = "/${var.APP}/${var.ENV}/snowflake/warehouse"
}

data "aws_ssm_parameter" "snowflake_database" {

  name     = "/${var.APP}/${var.ENV}/snowflake/database"
}

data "aws_ssm_parameter" "snowflake_schema" {

  name     = "/${var.APP}/${var.ENV}/snowflake/schema"
}

data "aws_secretsmanager_secret" "snowflake_credentials_secret" {

  name     = "${var.APP}-${var.ENV}-snowflake-credentials"
}

data "aws_secretsmanager_secret_version" "snowflake_credentials" {

  secret_id = data.aws_secretsmanager_secret.snowflake_credentials_secret.id
}

data "aws_iam_role" "glue_role" {

  name     = var.GLUE_ROLE_NAME
}

data "aws_kms_key" "secrets_manager_kms_key" {

  key_id   = "alias/aws/secretsmanager"
}

data "aws_kms_key" "s3_primary_key" {

  key_id   = "alias/${var.S3_KMS_KEY_ALIAS}"
}

data "aws_s3_bucket" "glue_scripts_bucket" {

  bucket   = var.GLUE_SCRIPTS_BUCKET_NAME
}
