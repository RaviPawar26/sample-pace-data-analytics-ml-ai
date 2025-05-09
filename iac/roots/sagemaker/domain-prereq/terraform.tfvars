// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

APP                                         = "miw"
ENV                                         = "snd"
AWS_PRIMARY_REGION                          = "us-east-1"
AWS_SECONDARY_REGION                        = "us-west-2"
S3_KMS_KEY_ALIAS                            = "miw-snd-s3-secret-key"
SSM_KMS_KEY_ALIAS                           = "miw-snd-systems-manager-secret-key"
DOMAIN_KMS_KEY_ALIAS                        = "miw-snd-glue-secret-key"
CLOUDWATCH_KMS_KEY_ALIAS                    = "miw-snd-cloudwatch-secret-key"
smus_domain_execution_role_name             = "smus-domain-execution-role"
smus_domain_service_role_name               = "smus-domain-service-role"
smus_domain_provisioning_role_name          = "smus-domain-provisioning-role"
smus_domain_bedrock_model_manage_role_name  = "smus_domain_bedrock_model_manage_role"
smus_domain_bedrock_model_consume_role_name = "smus-domain-bedrock-model-consume-role"
