// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_ssm_parameter" "vpc_id" {

  name = "/${var.APP}/${var.ENV}/vpc_id"
}

data "aws_ssm_parameter" "vpc_private_subnet_ids" {
  name = "/${var.APP}/${var.ENV}/vpc_private_subnet_ids"
}

data "aws_ssm_parameter" "glue_security_group" {
  name = "/${var.APP}/${var.ENV}/vpc-sg"
}

locals {
  VPC_ID                = data.aws_ssm_parameter.vpc_id.value
  PRIVATE_SUBNET1_ID =  split(",", data.aws_ssm_parameter.vpc_private_subnet_ids.value)[0] 
  GLUE_SECURITY_GROUP   = data.aws_ssm_parameter.glue_security_group.value
}