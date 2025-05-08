// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

resource "awscc_datazone_domain" "domain" {
  name                  = var.DOMAIN_NAME
  domain_execution_role = var.DOMAIN_EXECUTION_ROLE_ARN

}

# Publish Datazone SSM Parameter
resource "aws_ssm_parameter" "domain_id" {

  name        = "/${var.APP}/${var.ENV}/${var.DOMAIN_NAME}/domain_id"
  description = "The domain id"
  type        = "SecureString"
  value       = awscc_datazone_domain.domain.domain_id
  #   key_id      = var.KMS_KEY

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = var.USAGE
  }
}

resource "aws_sagemaker_domain" "example" {
  domain_name = "smlh-pilot-v2-sgdomain"
  auth_mode   = "IAM"
  vpc_id      = "vpc-07e447180f989a1cd"
  subnet_ids  = ["subnet-022a3b61e0427a553", "subnet-03e9fb7f85cae3127", "subnet-0cd269668f9b0f230"]

  default_user_settings {
    execution_role = var.DOMAIN_EXECUTION_ROLE_ARN
  }
}