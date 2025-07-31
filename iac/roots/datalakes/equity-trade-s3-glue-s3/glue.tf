// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_kms_key" "glue_kms_key" {

  key_id   = "alias/${var.GLUE_KMS_KEY_ALIAS}"
}

data "aws_kms_key" "cloudwatch_kms_key" {

  key_id   = "alias/${var.CLOUDWATCH_KMS_KEY_ALIAS}"
}

data "aws_iam_role" "glue_role" {

  name = var.GLUE_ROLE_NAME
}

resource "aws_glue_security_configuration" "glue_security_configuration" {

  name = "glue-security-configuration-equity-trade-s3-glue-s3"

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

data "aws_s3_bucket" "glue_scripts_bucket" {

  bucket = var.GLUE_SCRIPTS_BUCKET_NAME
}

resource "aws_s3_object" "equity_trade_glue_scripts" {

  for_each   = fileset("${path.module}/", "*.py")
  bucket     = data.aws_s3_bucket.glue_scripts_bucket.id
  key        = each.value
  source     = "${path.module}/${each.value}"
  kms_key_id = data.aws_kms_key.s3_kms_key.arn
}

resource "aws_glue_catalog_database" "glue_database" {

  name = "equity_trade_s3_glue_s3"

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "glue"
  }
}

resource "aws_lakeformation_permissions" "equity_trade_database_permissions" {

  principal   = data.aws_iam_role.glue_role.arn
  permissions = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]

  database {
    name = "equity_trade_s3_glue_s3"
  }

  depends_on = [aws_glue_catalog_database.glue_database]
}

resource "aws_lakeformation_permissions" "equity_trade_tables_permissions" {

  principal   = data.aws_iam_role.glue_role.arn
  permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

  table {
    database_name = "equity_trade_s3_glue_s3"
    wildcard      = true
  }

  depends_on = [aws_glue_catalog_database.glue_database, 
                aws_glue_catalog_table.equity_trade_hive, 
                aws_glue_catalog_table.equity_trade_iceberg]
}

resource "aws_glue_data_catalog_encryption_settings" "encryption_setting" {

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

resource "aws_glue_catalog_table" "equity_trade_hive" {

  name          = "equity_trade_s3_glue_s3_hive"
  database_name = aws_glue_catalog_database.glue_database.name

  table_type = "EXTERNAL_TABLE"

  parameters = {

    "classification"         = "csv"
    "areColumnsQuoted"       = "true"
    "delimiter"              = ","
    "skip.header.line.count" = "1"
    "typeOfData"             = "file"
    "EXTERNAL"               = "TRUE"
  }

  depends_on = [module.equity_trade_hive_bucket, 
                aws_lakeformation_permissions.hive_deployer_role, 
                aws_lakeformation_permissions.hive_glue_role]

  storage_descriptor {

    location      = "s3://${module.equity_trade_hive_bucket.bucket_name}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "csv-serde"
      serialization_library = "org.apache.hadoop.hive.serde2.OpenCSVSerde"

      parameters = {
        "separatorChar" = ","
        "quoteChar"     = "\""
        "escapeChar"    = "\\"
      }
    }

    columns {
      name = "order_id"
      type = "string"
    }

    columns {
      name = "trade_id"
      type = "string"
    }

    columns {
      name = "account_id"
      type = "string"
    }

    columns {
      name = "security_id"
      type = "string"
    }

    columns {
      name = "side"
      type = "string"
    }

    columns {
      name = "quantity"
      type = "int"
    }

    columns {
      name = "price"
      type = "double"
    }

    columns {
      name = "execution_time"
      type = "string"
    }

    columns {
      name = "fee"
      type = "double"
    }

    columns {
      name = "commission"
      type = "double"
    }
  }
}

resource "aws_glue_catalog_table" "equity_trade_iceberg" {

  name          = "equity_trade_s3_glue_s3_iceberg"
  database_name = aws_glue_catalog_database.glue_database.name

  table_type = "EXTERNAL_TABLE"

  open_table_format_input {
    iceberg_input {
      metadata_operation = "CREATE"
    }
  }

  depends_on = [module.equity_trade_iceberg_bucket, 
                aws_lakeformation_permissions.iceberg_deployer_role, 
                aws_lakeformation_permissions.iceberg_glue_role]

  storage_descriptor {

    location = "${var.EQUITY_TRADE_ICEBERG_BUCKET}"

    columns {
      name = "order_id"
      type = "string"
    }

    columns {
      name = "trade_id"
      type = "string"
    }

    columns {
      name = "account_id"
      type = "string"
    }

    columns {
      name = "security_id"
      type = "string"
    }

    columns {
      name = "side"
      type = "string"
    }

    columns {
      name = "quantity"
      type = "int"
    }

    columns {
      name = "price"
      type = "double"
    }

    columns {
      name = "execution_time"
      type = "timestamp"
    }

    columns {
      name = "fee"
      type = "double"
    }

    columns {
      name = "commission"
      type = "double"
    }
  }
}

resource "aws_glue_data_quality_ruleset" "equity_trade_hive_ruleset" {

  name        = "equity_trade_s3_glue_s3_hive_ruleset"
  description = "Data quality rules for equity trade hive table"

  # Target table for the ruleset
  target_table {
    database_name = aws_glue_catalog_database.glue_database.name
    table_name    = aws_glue_catalog_table.equity_trade_hive.name
  }

  # Rules written in DQDL (Data Quality Definition Language)
  ruleset = <<EOF
  Rules = [
    IsComplete "order_id",
    IsComplete "trade_id",
    IsComplete "account_id",
    IsComplete "security_id",
    IsComplete "side",
    IsComplete "quantity",
    IsComplete "price",
    IsComplete "execution_time",
    IsComplete "fee",
    IsComplete "commission"
  ]
  EOF
}

resource "aws_glue_data_quality_ruleset" "equity_trade_iceberg_ruleset" {

  name        = "equity_trade_s3_glue_s3_iceberg_ruleset"
  description = "Data quality rules for equity trade iceberg table"

  # Target table for the ruleset
  target_table {
    database_name = aws_glue_catalog_database.glue_database.name
    table_name    = aws_glue_catalog_table.equity_trade_iceberg.name
  }

  # Rules written in DQDL (Data Quality Definition Language)
  ruleset = <<EOF
  Rules = [
    IsComplete "order_id",
    IsComplete "trade_id",
    IsComplete "account_id",
    IsComplete "security_id",
    IsComplete "side",
    IsComplete "quantity",
    IsComplete "price",
    IsComplete "execution_time",
    IsComplete "fee",
    IsComplete "commission"
  ]
  EOF
}

resource "aws_glue_job" "equity_trade_hive_job" {

  name              = "equity-trade-s3-glue-s3-hive"
  description       = "equity-trade-s3-glue-s3-hive"
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 10

  security_configuration = aws_glue_security_configuration.glue_security_configuration.name

  command {
    script_location = "s3://${var.AWS_ACCOUNT_ID}-${var.APP}-${var.ENV}-glue-scripts/equity_trade_s3_glue_s3_hive.py"
  }

  default_arguments = {
    "--SOURCE_FILE"                      = var.EQUITY_TRADE_DATA_FILE
    "--DATABASE_NAME"                    = aws_glue_catalog_database.glue_database.name
    "--TABLE_NAME"                       = aws_glue_catalog_table.equity_trade_hive.name
    "--TempDir"                          = var.GLUE_TEMP_BUCKET
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-job-insights"              = "true"
    "--enable-metrics"                   = "true"
    "--enable-observability-metrics"     = "true"
    "--enable-spark-ui"                  = "true"
    "--spark-event-logs-path"            = var.GLUE_SPARK_LOGS_BUCKET
    "--enable-glue-datacatalog"          = "true"
    "--conf"                             = "spark.extraListeners=io.openlineage.spark.agent.OpenLineageSparkListener --conf spark.openlineage.transport.type=amazon_datazone_api --conf spark.openlineage.transport.domainId=${local.SMUS_DOMAIN_ID} --conf spark.openlineage.facets.custom_environment_variables=[AWS_DEFAULT_REGION;GLUE_VERSION;GLUE_COMMAND_CRITERIA;GLUE_PYTHON_VERSION;] --conf spark.glue.accountId=${local.account_id}"
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "Equity Trade"
  }
}

resource "aws_glue_job" "equity_trade_iceberg_job" {

  name              = "equity-trade-s3-glue-s3-iceberg"
  description       = "equity-trade-s3-glue-s3-iceberg"
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 10

  security_configuration = aws_glue_security_configuration.glue_security_configuration.name

  command {
    script_location = "s3://${var.AWS_ACCOUNT_ID}-${var.APP}-${var.ENV}-glue-scripts/equity_trade_s3_glue_s3_iceberg.py"
  }

  default_arguments = {
    "--SOURCE_FILE"                      = var.EQUITY_TRADE_DATA_FILE
    "--DATABASE_NAME"                    = aws_glue_catalog_database.glue_database.name
    "--TABLE_NAME"                       = aws_glue_catalog_table.equity_trade_iceberg.name
    "--TempDir"                          = var.GLUE_TEMP_BUCKET
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-job-insights"              = "true"
    "--enable-metrics"                   = "true"
    "--enable-observability-metrics"     = "true"
    "--enable-spark-ui"                  = "true"
    "--spark-event-logs-path"            = var.GLUE_SPARK_LOGS_BUCKET
    "--enable-glue-datacatalog"          = "true"
    "--datalake-formats"                 = "iceberg"
    "--conf"                             = "spark.sql.defaultCatalog=glue_catalog --conf spark.sql.catalog.glue_catalog.warehouse=${var.EQUITY_TRADE_ICEBERG_BUCKET} --conf spark.sql.catalog.glue_catalog=org.apache.iceberg.spark.SparkCatalog --conf spark.sql.catalog.glue_catalog.catalog-impl=org.apache.iceberg.aws.glue.GlueCatalog --conf spark.sql.catalog.glue_catalog.io-impl=org.apache.iceberg.aws.s3.S3FileIO --conf spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions --conf spark.extraListeners=io.openlineage.spark.agent.OpenLineageSparkListener --conf spark.openlineage.transport.type=amazon_datazone_api --conf spark.openlineage.transport.domainId=${local.SMUS_DOMAIN_ID} --conf spark.openlineage.facets.custom_environment_variables=[AWS_DEFAULT_REGION;GLUE_VERSION;GLUE_COMMAND_CRITERIA;GLUE_PYTHON_VERSION;] --conf spark.glue.accountId=${local.account_id}"
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "Equity Trade"
  }
}

resource "aws_glue_job" "equity_trade_s3_job" {

  name              = "equity-trade-s3-glue-s3table"
  description       = "equity-trade-s3-glue-s3table"
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 10

  security_configuration = aws_glue_security_configuration.glue_security_configuration.name

  command {
    script_location = "s3://${var.AWS_ACCOUNT_ID}-${var.APP}-${var.ENV}-glue-scripts/equity_trade_s3_glue_s3table.py"
  }

  default_arguments = {
    "--SOURCE_FILE"                       = var.EQUITY_TRADE_DATA_FILE
    "--NAMESPACE"                         = var.APP
    "--TABLE_BUCKET_ARN"                  = "arn:aws:s3tables:${var.AWS_PRIMARY_REGION}:${var.AWS_ACCOUNT_ID}:bucket/equity-trade-s3-glue-s3table"
    "--extra-jars"                        = "s3://${var.AWS_ACCOUNT_ID}-${var.APP}-${var.ENV}-glue-jars/s3-tables-catalog-for-iceberg-runtime-0.1.7.jar"
    "--datalake-formats"                  = "iceberg"
    "--user-jars-first"                   = "true"
    "--TempDir"                           = var.GLUE_TEMP_BUCKET
    "--enable-continuous-cloudwatch-log"  = "true"
    "--enable-job-insights"               = "true"
    "--enable-metrics"                    = "true"
    "--enable-observability-metrics"      = "true"
    "--enable-spark-ui"                   = "true"
    "--spark-event-logs-path"             = var.GLUE_SPARK_LOGS_BUCKET
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "Equity Trade"
  }
}


