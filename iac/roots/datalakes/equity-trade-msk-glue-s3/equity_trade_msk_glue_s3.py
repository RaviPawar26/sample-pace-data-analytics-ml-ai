# Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

from pyspark.sql import DataFrame, Row
import datetime
from awsglue import DynamicFrame

args = getResolvedOptions(sys.argv, ['JOB_NAME', 'CONNECTION_NAME', 'TOPIC_NAME', 'DATA_DATABASE_NAME', 'DATA_TABLE_NAME', 'METADATA_DATABASE_NAME', 'METADATA_TABLE_NAME'])

CONNECTION_NAME = args.get("CONNECTION_NAME")
TOPIC_NAME = args.get("TOPIC_NAME")
DATA_DATABASE_NAME = args.get("DATA_DATABASE_NAME")
DATA_TABLE_NAME = args.get("DATA_TABLE_NAME")
METADATA_DATABASE_NAME = args.get("METADATA_DATABASE_NAME")
METADATA_TABLE_NAME = args.get("METADATA_TABLE_NAME")

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Script generated for node Apache Kafka
dataframe_ApacheKafka_node1730958321534 = glueContext.create_data_frame.from_options(connection_type="kafka",connection_options={"connectionName": CONNECTION_NAME, "classification": "json", "startingOffsets": "earliest", "topicName": TOPIC_NAME, "inferSchema": "true", "typeOfData": "kafka", "failOnDataLoss": "false"}, transformation_ctx="dataframe_ApacheKafka_node1730958321534")

def processBatch(data_frame, batchId):
    if (data_frame.count() > 0):
        ApacheKafka_node1730958321534 = DynamicFrame.fromDF(data_frame, glueContext, "from_data_frame")
        # Script generated for node AWS Glue Data Catalog
        AWSGlueDataCatalog_node1730958324693 = glueContext.write_dynamic_frame.from_catalog(frame=ApacheKafka_node1730958321534, database=DATA_DATABASE_NAME, table_name=DATA_TABLE_NAME, transformation_ctx="AWSGlueDataCatalog_node1730958324693")

        # Script generated for node AWS Glue Data Catalog
        AWSGlueDataCatalog_node1730958325901_df = ApacheKafka_node1730958321534.toDF()
        AWSGlueDataCatalog_node1730958325901 = glueContext.write_data_frame.from_catalog(frame=AWSGlueDataCatalog_node1730958325901_df, database=METADATA_DATABASE_NAME, table_name=METADATA_TABLE_NAME, additional_options={})

glueContext.forEachBatch(frame = dataframe_ApacheKafka_node1730958321534, batch_function = processBatch, options = {"windowSize": "100 seconds", "checkpointLocation": args["TempDir"] + "/" + args["JOB_NAME"] + "/checkpoint/"})
job.commit()