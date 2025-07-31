// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "AWS_ACCOUNT_ID" {

  type = string
}

variable "APP" {

  description = "Application name"
  type        = string
}

variable "ENV" {

  description = "Environment name"
  type        = string
}

variable "AWS_PRIMARY_REGION" {

  description = "AWS Primary Region"
  type        = string
}

variable "SNOWFLAKE_TABLE_NAME" {

  description = "Name of the Snowflake table"
  type        = string
}

variable "SNOWFLAKE_SECRET_NAME" {

  description = "Name of the Snowflake secret"
  type        = string
}

variable "S3_KMS_KEY_ALIAS" {

  type = string
}

variable "GLUE_SCRIPTS_BUCKET_NAME" {

  description = "Name of the S3 bucket for Glue scripts"
  type        = string
}

variable "GLUE_ROLE_NAME" {

  description = "Name of the Glue role"
  type        = string
}

variable "GLUE_SPARK_LOGS_BUCKET" {

  type = string
}

variable "GLUE_TEMP_BUCKET" {

  type = string
}

variable "GLUE_SECURITY_CONFIGURATION" {

  description = "Name of the Glue security configuration"
  type        = string
}

variable "GLUE_KMS_KEY_ALIAS" {

  type = string
}

variable "CLOUDWATCH_KMS_KEY_ALIAS" {

  type = string
}