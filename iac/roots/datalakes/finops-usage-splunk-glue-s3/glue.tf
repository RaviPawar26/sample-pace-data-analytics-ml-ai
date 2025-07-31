// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_iam_role" "glue_role" {

  name = var.GLUE_ROLE_NAME
}

data "aws_kms_key" "glue_kms_key" {

  key_id   = "alias/${var.GLUE_KMS_KEY_ALIAS}"
}

data "aws_kms_key" "cloudwatch_kms_key" {

  key_id   = "alias/${var.CLOUDWATCH_KMS_KEY_ALIAS}"
}

data "aws_secretsmanager_secret_version" "splunk_creds" {

  secret_id = aws_secretsmanager_secret.splunk_credentials.id
  depends_on = [
    aws_secretsmanager_secret_version.splunk_credentials
  ]
}

locals {
  splunk_creds = jsondecode(data.aws_secretsmanager_secret_version.splunk_creds.secret_string)
}

resource "aws_glue_security_configuration" "glue_security_configuration_usage" {

  name = "glue-security-configuration-finops-usage-splunk-glue-s3"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "SSE-KMS"
      kms_key_arn                = data.aws_kms_key.cloudwatch_kms_key.arn
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "CSE-KMS"
      kms_key_arn                   = data.aws_kms_key.glue_kms_key.arn
    }

    s3_encryption {
      s3_encryption_mode = "SSE-KMS"
      kms_key_arn        = data.aws_kms_key.glue_kms_key.arn
    }
  }
}

resource "aws_glue_data_catalog_encryption_settings" "encryption_setting_usage" {

  data_catalog_encryption_settings {

    connection_password_encryption {
      aws_kms_key_id                       = data.aws_kms_key.glue_kms_key.arn
      return_connection_password_encrypted = true
    }

    encryption_at_rest {
      catalog_encryption_mode = "SSE-KMS"
      sse_aws_kms_key_id      = data.aws_kms_key.glue_kms_key.arn
    }
  }
}

data "aws_s3_bucket" "glue_scripts_bucket" {

  bucket = var.GLUE_SCRIPTS_BUCKET_NAME
}

resource "aws_s3_object" "usage_glue_scripts" {

  for_each   = fileset("${path.module}/", "*.py")
  bucket     = data.aws_s3_bucket.glue_scripts_bucket.id
  key        = each.value
  source     = "${path.module}/${each.value}"
  kms_key_id = data.aws_kms_key.s3_kms_key.arn
}

# Glue Database
resource "aws_glue_catalog_database" "usage_database" {

  name = "finops_usage_splunk_glue_s3"

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "usage"
  }
}

resource "aws_lakeformation_permissions" "database_permissions" {

  principal   = data.aws_iam_role.glue_role.arn
  permissions = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]

  database {
    name = "finops_usage_splunk_glue_s3"
  }

  depends_on = [aws_glue_catalog_database.usage_database]
}

resource "aws_lakeformation_permissions" "tables_permissions" {

  principal   = data.aws_iam_role.glue_role.arn
  permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

  table {
    database_name = "finops_usage_splunk_glue_s3"
    wildcard      = true
  }

  depends_on = [aws_glue_catalog_database.usage_database]
}

# Target Iceberg table with same schema
resource "aws_glue_catalog_table" "usage_iceberg" {

  name          = "finops_usage_splunk_glue_s3_iceberg"
  database_name = aws_glue_catalog_database.usage_database.name
  table_type    = "EXTERNAL_TABLE"

  open_table_format_input {
    iceberg_input {
      metadata_operation = "CREATE"
    }
  }

  depends_on = [module.usage_iceberg_bucket, 
                aws_lakeformation_permissions.iceberg_deployer_role,
                aws_lakeformation_permissions.iceberg_glue_role]

  storage_descriptor {
    location = var.USAGE_ICEBERG_BUCKET

    columns {
      name = "_time"
      type = "timestamp"
    }
    columns {
      name = "host"
      type = "string"
    }
    columns {
      name = "source"
      type = "string"
    }
    columns {
      name = "sourcetype"
      type = "string"
    }
  }
}

resource "aws_glue_connection" "splunk_vpc_connection" {

  name            = "${var.APP}-${var.ENV}-splunk-vpc-connection"
  connection_type = "NETWORK"

  physical_connection_requirements {
    availability_zone      = aws_instance.splunk.availability_zone
    security_group_id_list = [local.GLUE_SECURITY_GROUP]
    subnet_id              = local.PRIVATE_SUBNET1_ID
  }
}

# ETL Job
resource "aws_glue_job" "usage_iceberg_job" {

  name              = "finops-usage-splunk-glue-s3-iceberg"
  description       = "finops-usage-splunk-glue-s3-iceberg"
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 10

  security_configuration = aws_glue_security_configuration.glue_security_configuration_usage.name
  connections            = ["${aws_glue_connection.splunk_vpc_connection.name}"]

  execution_property {
    max_concurrent_runs = 1
  }

  command {
    script_location = "s3://${var.AWS_ACCOUNT_ID}-${var.APP}-${var.ENV}-glue-scripts/finops_usage_splunk_glue_s3_iceberg.py"
  }

  default_arguments = {
    "--additional-python-modules"        = "requests"
    "--enable-glue-datacatalog"          = "true"
    "--datalake-formats"                 = "iceberg"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-job-insights"              = "true"
    "--enable-metrics"                   = "true"
    "--TempDir"                          = var.GLUE_TEMP_BUCKET
    "--spark-event-logs-path"            = var.GLUE_SPARK_LOGS_BUCKET
    "--SPLUNK_HOST"                      = aws_instance.splunk.private_ip
    "--TARGET_DATABASE"                  = aws_glue_catalog_database.usage_database.name
    "--TARGET_TABLE"                     = aws_glue_catalog_table.usage_iceberg.name
    "--SPLUNK_ICEBERG_BUCKET"            = var.USAGE_ICEBERG_BUCKET
    "--SPLUNK_SECRET_NAME"               = aws_secretsmanager_secret.splunk_credentials.arn
    "--conf" = join(" --conf ", [
      "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions",
      "spark.sql.catalog.aws_glue=org.apache.iceberg.spark.SparkCatalog",
      "spark.sql.catalog.aws_glue.warehouse=${var.USAGE_ICEBERG_BUCKET}",
      "spark.sql.catalog.aws_glue.catalog-impl=org.apache.iceberg.aws.glue.GlueCatalog",
      "spark.sql.catalog.aws_glue.io-impl=org.apache.iceberg.aws.s3.S3FileIO",
      "spark.sql.defaultCatalog=aws_glue"
    ])
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "splunk"
  }
}

resource "aws_glue_job" "usage_s3table_job" {

  name              = "finops-usage-splunk-glue-s3table"
  description       = "finops-usage-splunk-glue-s3table"
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 10

  security_configuration = aws_glue_security_configuration.glue_security_configuration_usage.name
  connections            = ["${aws_glue_connection.splunk_vpc_connection.name}"]

  command {
    script_location = "s3://${var.AWS_ACCOUNT_ID}-${var.APP}-${var.ENV}-glue-scripts/finops_usage_splunk_glue_s3table.py"
  }

  default_arguments = {
    "--extra-jars"                       = "s3://${var.AWS_ACCOUNT_ID}-${var.APP}-${var.ENV}-glue-jars/s3-tables-catalog-for-iceberg-runtime-0.1.7.jar"
    "--TABLE_BUCKET_ARN"                 = "arn:aws:s3tables:${var.AWS_PRIMARY_REGION}:${var.AWS_ACCOUNT_ID}:bucket/finops-usage-splunk-glue-s3table"
    "--SPLUNK_HOST"                      = aws_instance.splunk.private_ip
    "--SPLUNK_SECRET_NAME"               = aws_secretsmanager_secret.splunk_credentials.arn
    "--NAMESPACE"                        = var.APP
    "--datalake-formats"                 = "iceberg"
    "--user-jars-first"                  = "true"
    "--additional-python-modules"        = "requests"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-job-insights"              = "true"
    "--enable-metrics"                   = "true"
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "splunk"
  }
}

# Glue job trigger for S3 Iceberg Bucket
resource "aws_glue_trigger" "usage_iceberg_job_trigger" {

  name     = "fiopns-usage-splunk-glue-s3-job-trigger"
  type     = "SCHEDULED"
  schedule = "cron(0 7 * * ? *)" # Runs once every day at 7am UTC
  # schedule = "cron(0/5 * * * ? *)" # Runs every 5 minutes

  actions {
    job_name = aws_glue_job.usage_iceberg_job.name  
  }

  enabled = true
}

# Glue job trigger for S3 Table Bucket
resource "aws_glue_trigger" "usage_s3table_job_trigger" {

  name     = "finops-usage-splunk-glue-s3table-job-trigger"
  type     = "SCHEDULED"
  schedule = "cron(0 7 * * ? *)" # Runs once every day at 7am UTC
  # schedule = "cron(0/5 * * * ? *)" # Runs every 5 minutes

  actions {
    job_name = aws_glue_job.usage_s3table_job.name  
  }

  enabled = true
}

