// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

terraform {
  backend "s3" {
    bucket         = "sndlh-633391536196-us-east-1"
    dynamodb_table = "sndlh-lock"
    region         = "us-east-1"
    key            = "snd/idc-org/terraform.tfstate"
    encrypt        = true
  }
}



