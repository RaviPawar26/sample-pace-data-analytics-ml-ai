// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

terraform {
  backend "s3" {
    bucket         = "sndlh-904233109241-us-east-1"
    key            = "snd/project-prereq/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = false
  }
}