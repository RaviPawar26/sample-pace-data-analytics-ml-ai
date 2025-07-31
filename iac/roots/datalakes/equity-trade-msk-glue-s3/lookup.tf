// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0
data "aws_ssm_parameter" "vpc_id" {

  name = "/${var.APP}/${var.ENV}/vpc_id"
}

data "aws_ssm_parameter" "vpc_private_subnet_ids" {

  name = "/${var.APP}/${var.ENV}/vpc_private_subnet_ids"
}

data "aws_vpc" "vpc" {
  id = data.aws_ssm_parameter.vpc_id.value
}

data "aws_ssm_parameter" "glue_security_group" {

  name = "/${var.APP}/${var.ENV}/vpc-sg"
}

data "aws_secretsmanager_secret_version" "msk_endpoint" {
  secret_id = "${var.APP}-${var.ENV}-msk-endpoint"
}

locals {
  PRIVATE_SUBNET1_ID  = split(",", data.aws_ssm_parameter.vpc_private_subnet_ids.value)[0]
  PRIVATE_SUBNET2_ID  = split(",", data.aws_ssm_parameter.vpc_private_subnet_ids.value)[1]
  PRIVATE_SUBNET3_ID  = split(",", data.aws_ssm_parameter.vpc_private_subnet_ids.value)[2]
  VPC_ID              = data.aws_ssm_parameter.vpc_id.value
  GLUE_SECURITY_GROUP = data.aws_ssm_parameter.glue_security_group.value
  MSK_ENDPOINT        = data.aws_secretsmanager_secret_version.msk_endpoint.secret_string
}
