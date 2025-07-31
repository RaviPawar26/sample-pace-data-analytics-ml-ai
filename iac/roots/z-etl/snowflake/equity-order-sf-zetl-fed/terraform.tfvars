// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

AWS_ACCOUNT_ID              = "###AWS_ACCOUNT_ID###"
APP                         = "###APP_NAME###"
ENV                         = "###ENV_NAME###"
AWS_PRIMARY_REGION          = "###AWS_PRIMARY_REGION###"
GLUE_SCRIPTS_BUCKET_NAME    = "###AWS_ACCOUNT_ID###-###APP_NAME###-###ENV_NAME###-glue-scripts"
S3_KMS_KEY_ALIAS            = "###APP_NAME###-###ENV_NAME###-s3-secret-key"
GLUE_SECURITY_CONFIGURATION = "###APP_NAME###-###ENV_NAME###-glue-security-configuration"
SNOWFLAKE_SECRET_NAME       = "###APP_NAME###-###ENV_NAME###-snowflake-credentials"
GLUE_SPARK_LOGS_BUCKET      = "s3://###AWS_ACCOUNT_ID###-###APP_NAME###-###ENV_NAME###-glue-spark-logs/"
GLUE_TEMP_BUCKET            = "s3://###AWS_ACCOUNT_ID###-###APP_NAME###-###ENV_NAME###-glue-temp/"
GLUE_ROLE_NAME              = "###APP_NAME###-###ENV_NAME###-glue-role"
SNOWFLAKE_TABLE_NAME        = "equity_order"
GLUE_KMS_KEY_ALIAS          = "###APP_NAME###-###ENV_NAME###-glue-secret-key"
CLOUDWATCH_KMS_KEY_ALIAS    = "###APP_NAME###-###ENV_NAME###-cloudwatch-secret-key"
