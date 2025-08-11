// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

APP                       = "mit"
ENV                       = "snd"
AWS_PRIMARY_REGION        = "us-east-1"
AWS_SECONDARY_REGION      = "us-west-2"
PRIMARY_CIDR              = "10.1.0.0/16"
PRIMARY_PRIVATE_SUBNETS   = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
PRIMARY_PUBLIC_SUBNETS    = ["10.1.4.0/24", "10.1.5.0/24", "10.1.6.0/24"]
SECONDARY_CIDR            = "10.2.0.0/16"
SECONDARY_PRIVATE_SUBNETS = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
SECONDARY_PUBLIC_SUBNETS  = ["10.2.4.0/24", "10.2.5.0/24", "10.2.6.0/24"]
SSM_KMS_KEY_ALIAS         = "mit-snd-systems-manager-secret-key"
