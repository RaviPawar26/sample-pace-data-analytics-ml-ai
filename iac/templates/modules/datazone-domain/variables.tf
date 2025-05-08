// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "APP" {
  type = string
  default = "miw-iaac"
}

variable "ENV" {
  type    = string
  default = "sbx"
}

variable "DOMAIN_NAME" {
  type    = string
  default = "smlh-pilot-v1"
}

variable "DOMAIN_EXECUTION_ROLE_ARN" {
  type    = string
  default = "arn:aws:iam::633391536196:role/service-role/AmazonSageMakerDomainExecution"
}

# variable "KMS_KEY" {
#   type = string
# }

variable "USAGE" {
  type    = string
  default = "miw-test"
}

