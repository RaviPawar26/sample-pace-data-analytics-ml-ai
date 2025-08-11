// Copyright 2025 Amazon.com and its affiliates; all rights reserved.
// This file is Amazon Web Services Content and may not be duplicated or distributed without permission.

terraform {

  backend "s3" {

    bucket         = "mit-snd-tf-back-end-904233109241-us-east-1"
    key            = "snd/datalakes/equity-trade-msk-flink-msk/terraform.tfstate"
    dynamodb_table = "mit-snd-tf-back-end-lock"
    region         = "us-east-1"
    encrypt        = true
  }
}
