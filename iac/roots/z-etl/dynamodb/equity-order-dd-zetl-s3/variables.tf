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

variable "Z_ETL_DYNAMODB_TABLE" {

  type = string
}

variable "Z_ETL_DYNAMODB_DATA_BUCKET" {

  type = string
}

variable "S3_KMS_KEY_ALIAS" {
  

  type = string
}

variable "GLUE_ROLE_NAME" {

  type = string
}

variable "DYNAMODB_PRIMARY_KMS_KEY_ALIAS" {

  type = string
}

variable "GLUE_PRIMARY_KMS_KEY_ALIAS" {
  
  type = string
}