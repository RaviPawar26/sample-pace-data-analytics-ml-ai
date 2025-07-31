// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "AWS_ACCOUNT_ID" {

  type = string
}

variable "APP" {

  type = string
}

variable "ENV" {

  type = string
}

variable "AWS_PRIMARY_REGION" {

  type = string
}

variable "S3_KMS_KEY_ALIAS" {

  type = string
}

# SSM KMS Key Alias (needed for data source)
variable "SSM_KMS_KEY_ALIAS" {
  description = "KMS key alias for SSM parameter encryption"
  type        = string
}


variable "FLINK_S3_BUCKET" {

  type = string
}

variable "FLINK_S3_FILE_KEY" {

  type = string
}

variable "FLINK_APP_RUNTIME_ENV" {

  type = string
}

variable "FLINK_APP_PARALLELISM" {

  type    = number
}

variable "FLINK_APP_ALLOW_NON_RESTORED_STATE" {

  type = string
}


variable "FLINK_APP_PARALLELISM_PER_KPU" {

  type    = number
}

variable "FLINK_APP_AUTOSCALING_ENABLED" {

  type    = bool
}

variable "FLINK_APP_MONITORING_LOG_LEVEL" {

  type    = string
}

variable "FLINK_APP_MONITORING_METRICS_LEVEL" {

  type    = string
}

variable "FLINK_APP_SNAPSHOTS_ENABLED" {

  type    = bool
}

variable "FLINK_APP_START" {

  type    = bool
}

variable "CODE_CONTENT_TYPE" {

  type    = string
}

variable "FLINK_APP_ENVIRONMENT_VARIABLES" {

  type = map(string)
}
