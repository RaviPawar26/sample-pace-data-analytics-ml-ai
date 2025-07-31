// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

AWS_ACCOUNT_ID                      = "###AWS_ACCOUNT_ID###"
APP                                 = "###APP_NAME###"
ENV                                 = "###ENV_NAME###"
AWS_PRIMARY_REGION                  = "###AWS_PRIMARY_REGION###"
Z_ETL_DYNAMODB_TABLE                = "###APP_NAME###-###ENV_NAME###-equity-orders-db-table"
Z_ETL_DYNAMODB_DATA_BUCKET          = "###AWS_ACCOUNT_ID###-###APP_NAME###-###ENV_NAME###-equity-order-dd-zetl-s3-data"
S3_KMS_KEY_ALIAS                    = "###APP_NAME###-###ENV_NAME###-s3-secret-key"
GLUE_ROLE_NAME                      = "###APP_NAME###-###ENV_NAME###-glue-role"
DYNAMODB_PRIMARY_KMS_KEY_ALIAS      = "###APP_NAME###-###ENV_NAME###-dynamodb-secret-key"
GLUE_PRIMARY_KMS_KEY_ALIAS          = "###APP_NAME###-###ENV_NAME###-glue-secret-key"