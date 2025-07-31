// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

AWS_ACCOUNT_ID              = "###AWS_ACCOUNT_ID###"
APP                         = "###APP_NAME###"
ENV                         = "###ENV_NAME###"
AWS_PRIMARY_REGION          = "###AWS_PRIMARY_REGION###"
S3_KMS_KEY_ALIAS            = "###APP_NAME###-###ENV_NAME###-s3-secret-key"
EQUITY_TRADE_DATA_BUCKET    = "###AWS_ACCOUNT_ID###-###APP_NAME###-###ENV_NAME###-equity-trade-s3-glue-s3-data"
GLUE_SCRIPTS_BUCKET_NAME    = "###AWS_ACCOUNT_ID###-###APP_NAME###-###ENV_NAME###-glue-scripts"
GLUE_ROLE_NAME              = "###APP_NAME###-###ENV_NAME###-glue-role"
EQUITY_TRADE_DATA_FILE      = "s3://###AWS_ACCOUNT_ID###-###APP_NAME###-###ENV_NAME###-equity-trade-s3-glue-s3-data/equity_trades.csv"
EQUITY_TRADE_ICEBERG_BUCKET = "s3://###AWS_ACCOUNT_ID###-###APP_NAME###-###ENV_NAME###-equity-trade-s3-glue-s3-iceberg/"
GLUE_SPARK_LOGS_BUCKET      = "s3://###AWS_ACCOUNT_ID###-###APP_NAME###-###ENV_NAME###-glue-spark-logs/"
GLUE_TEMP_BUCKET            = "s3://###AWS_ACCOUNT_ID###-###APP_NAME###-###ENV_NAME###-glue-temp/"
GLUE_KMS_KEY_ALIAS          = "###APP_NAME###-###ENV_NAME###-glue-secret-key"
CLOUDWATCH_KMS_KEY_ALIAS    = "###APP_NAME###-###ENV_NAME###-cloudwatch-secret-key"
EVENTBRIDGE_ROLE_NAME       = "###APP_NAME###-###ENV_NAME###-eventbridge-role"
