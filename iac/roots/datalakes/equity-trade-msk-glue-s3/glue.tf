// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_kms_key" "glue_kms_key" {

  key_id   = "alias/${var.GLUE_KMS_KEY_ALIAS}"
}

data "aws_kms_key" "s3_kms_key" {

  key_id   = "alias/${var.S3_KMS_KEY_ALIAS}"
}

data "aws_kms_key" "cloudwatch_kms_key" {

  key_id   = "alias/${var.CLOUDWATCH_KMS_KEY_ALIAS}"
}

data "aws_iam_role" "glue_role" {

  name = var.GLUE_ROLE_NAME
}

data "aws_subnet" "subnet1" {

  id = local.PRIVATE_SUBNET1_ID
}

resource "aws_glue_security_configuration" "glue_security_configuration" {

  name = "glue-security-configuration-equity-trade-msk-glue-s3"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "SSE-KMS"
      kms_key_arn = data.aws_kms_key.cloudwatch_kms_key.arn
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "CSE-KMS"
      kms_key_arn = data.aws_kms_key.glue_kms_key.arn
    }

    s3_encryption {
      s3_encryption_mode = "SSE-KMS"
      kms_key_arn = data.aws_kms_key.glue_kms_key.arn
    }
  }
}

resource "aws_glue_connection" "msk_connection" {

  name            = "equity-trade-msk-glue-s3-msk-glue-connection"
  description     = "Connection to MSK cluster"
  connection_type = "KAFKA"

  connection_properties = {

    KAFKA_BOOTSTRAP_SERVERS = local.MSK_ENDPOINT
    KAFKA_SSL_ENABLED = "true"
    KAFKA_SASL_MECHANISM = "AWS_MSK_IAM"
  }

  physical_connection_requirements {

    availability_zone       = data.aws_subnet.subnet1.availability_zone
    subnet_id               = local.PRIVATE_SUBNET1_ID
    security_group_id_list  = [local.GLUE_SECURITY_GROUP]
  }
}

data "aws_s3_bucket" "glue_scripts_bucket" {

  bucket = var.GLUE_SCRIPTS_BUCKET_NAME
}

resource "aws_s3_object" "price_glue_scripts" {

  for_each   = fileset("${path.module}/", "*.py")
  bucket     = data.aws_s3_bucket.glue_scripts_bucket.id
  key        = each.value
  source     = "${path.module}/${each.value}"
  kms_key_id = data.aws_kms_key.s3_kms_key.arn
}

resource "aws_glue_catalog_database" "glue_database" {

  name = "equity_trade_msk_glue_s3"
}

resource "aws_glue_data_catalog_encryption_settings" "encryption_setting" {

  data_catalog_encryption_settings {

    connection_password_encryption {
      aws_kms_key_id                       = data.aws_kms_key.glue_kms_key.arn
      return_connection_password_encrypted = true
    }

    encryption_at_rest {
      catalog_encryption_mode         = "SSE-KMS"
      sse_aws_kms_key_id              = data.aws_kms_key.glue_kms_key.arn
    }
  }
}

resource "aws_lakeformation_permissions" "trade_database_permissions" {

  principal   = data.aws_iam_role.glue_role.arn
  permissions = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]

  database {
    name = "equity_trade_msk_glue_s3"
  }

  depends_on = [aws_glue_catalog_database.glue_database]
}

resource "aws_lakeformation_permissions" "trade_tables_permissions" {

  principal   = data.aws_iam_role.glue_role.arn
  permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

  table {
    database_name = "equity_trade_msk_glue_s3"
    wildcard      = true
  }

  depends_on = [aws_glue_catalog_database.glue_database, 
                aws_glue_catalog_table.trade_table_hive, 
                aws_glue_catalog_table.trade_table_iceberg]
}

resource "aws_glue_catalog_table" "trade_table_hive" {

  name          = "equity_trade_msk_glue_s3_hive"
  database_name = aws_glue_catalog_database.glue_database.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "json"
  }

  storage_descriptor {

    location      = var.TRADE_HIVE_BUCKET
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "json-serde"
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "message_type"
      type = "string"
    }

    columns {
      name = "timestamp"
      type = "string"
    }

    columns {
      name = "symbol"
      type = "string"
    }

    columns {
      name = "market_center"
      type = "string"
    }

    columns {
      name = "execution_id"
      type = "string"
    }

    columns {
      name = "last_price"
      type = "string"
    }

    columns {
      name = "last_size"
      type = "string"
    }

    columns {
      name = "cumulative_volume"
      type = "string"
    }

    columns {
      name = "national_volume"
      type = "string"
    }

    columns {
      name = "flags"
      type = "string"
    }
  }

  depends_on = [module.data_trade_hive_bucket]
}

resource "aws_glue_catalog_table" "trade_table_iceberg" {

  name          = "equity_trade_msk_glue_s3_iceberg"
  database_name = aws_glue_catalog_database.glue_database.name

  table_type = "EXTERNAL_TABLE"

  open_table_format_input {
    iceberg_input {
      metadata_operation = "CREATE"
    }
  }

  storage_descriptor {

    location      = var.TRADE_ICEBERG_BUCKET

    columns {
      name = "message_type"
      type = "string"
    }

    columns {
      name = "timestamp"
      type = "string"
    }

    columns {
      name = "symbol"
      type = "string"
    }

    columns {
      name = "market_center"
      type = "string"
    }

    columns {
      name = "execution_id"
      type = "string"
    }

    columns {
      name = "last_price"
      type = "string"
    }

    columns {
      name = "last_size"
      type = "string"
    }

    columns {
      name = "cumulative_volume"
      type = "string"
    }

    columns {
      name = "national_volume"
      type = "string"
    }

    columns {
      name = "flags"
      type = "string"
    }
  }

  depends_on = [module.data_trade_iceberg_bucket]
}

resource "aws_glue_job" "trade_job" {

  name              = "equity-trade-msk-glue-s3"
  description       = "equity-trade-msk-glue-s3"
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 100

  connections = [aws_glue_connection.msk_connection.name]

  security_configuration = aws_glue_security_configuration.glue_security_configuration.name

  command {
    name            = "gluestreaming"
    script_location = "s3://${var.AWS_ACCOUNT_ID}-${var.APP}-${var.ENV}-glue-scripts/equity_trade_msk_glue_s3.py"
  }
 
  default_arguments = {
    "--CONNECTION_NAME"                   = aws_glue_connection.msk_connection.name
    "--TOPIC_NAME"                        = var.TRADE_TOPIC
    "--DATA_DATABASE_NAME"                = aws_glue_catalog_database.glue_database.name
    "--DATA_TABLE_NAME"                   = aws_glue_catalog_table.trade_table_hive.name
    "--METADATA_DATABASE_NAME"            = aws_glue_catalog_database.glue_database.name
    "--METADATA_TABLE_NAME"               = aws_glue_catalog_table.trade_table_iceberg.name
    "--TempDir"                           = var.GLUE_TEMP_BUCKET
    "--enable-continuous-cloudwatch-log"  = "true"
    "--enable-job-insights"               = "true"   
    "--enable-metrics"                    = "true"
    "--enable-observability-metrics"      = "true"
    "--enable-spark-ui"                   = "true"
    "--spark-event-logs-path"             = var.GLUE_SPARK_LOGS_BUCKET
    "--enable-glue-datacatalog"           = "true" 
    "--datalake-formats"                  = "iceberg"
    "--conf"                              = "spark.sql.defaultCatalog=glue_catalog --conf spark.sql.catalog.glue_catalog.warehouse=${var.TRADE_ICEBERG_BUCKET} --conf spark.sql.catalog.glue_catalog=org.apache.iceberg.spark.SparkCatalog --conf spark.sql.catalog.glue_catalog.catalog-impl=org.apache.iceberg.aws.glue.GlueCatalog --conf spark.sql.catalog.glue_catalog.io-impl=org.apache.iceberg.aws.s3.S3FileIO --conf spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions"
  }
}

