// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

terraform {

  backend "s3" {

    bucket         = "mit-snd-tf-back-end-904233109241-us-east-1"
    key            = "snd/sagemaker/producer-project/terraform.tfstate"
    dynamodb_table = "mit-snd-tf-back-end-lock"
    region         = "us-east-1"
    encrypt        = true
  }
}
