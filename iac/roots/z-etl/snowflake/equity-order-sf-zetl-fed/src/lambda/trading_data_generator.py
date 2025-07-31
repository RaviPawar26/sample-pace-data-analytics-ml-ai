#!/usr/bin/env python3
"""
This AWS Glue ETL script generates 10,000 synthetic trading order records with randomized attributes
(like order type, security ID, quantity, price, etc.) based on predefined lists and rules.

It then loads this generated data into a specified Snowflake table. Key Snowflake connection
parameters (URL, database, schema, table, warehouse) are passed to the script
as Glue job arguments. Username and password for Snowflake are retrieved from AWS Secrets Manager.

The script uses AWS Glue's built-in Snowflake connector to write the data.
"""

import sys
import random
import uuid
import boto3
import json
from decimal import Decimal
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.types import StructType, StructField, StringType, IntegerType, DecimalType

args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'SNOWFLAKE_SECRET_NAME',
    'SNOWFLAKE_URL',
    'SNOWFLAKE_WAREHOUSE_NAME',
    'SNOWFLAKE_SCHEMA_NAME',
    'SNOWFLAKE_DATABASE_NAME',
    'SNOWFLAKE_TABLE_NAME'
])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# --- Function to Retrieve Credentials from AWS Secrets Manager ---
def get_snowflake_credentials_from_secret(secret_name_arg):
    """
    Retrieves Snowflake username and password from AWS Secrets Manager.
    Expects the secret to have keys 'USERNAME' and 'PASSWORD'.
    """
    client = boto3.client('secretsmanager')

    if not secret_name_arg:
        print("ERROR: SNOWFLAKE_SECRET_NAME job argument is not provided.")
        raise ValueError("SNOWFLAKE_SECRET_NAME is required.")

    try:
        print(f"Attempting to retrieve secret: {secret_name_arg}")
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name_arg
        )
        if 'SecretString' in get_secret_value_response:
            secret = json.loads(get_secret_value_response['SecretString'])
            username = secret.get('username')
            password = secret.get('password')
            if not username or not password:
                print(
                    "ERROR: 'USERNAME' or 'PASSWORD' key not found in the secret data.")
                raise KeyError("'USERNAME' or 'PASSWORD' not found in secret.")
            print("Successfully retrieved USERNAME from secret.")
            return username, password
        else:
            print(
                f"ERROR: Secret {secret_name_arg} does not contain a SecretString.")
            raise ValueError(
                f"Secret {secret_name_arg} does not contain a SecretString.")
    except Exception as e:
        print(
            f"ERROR: Could not retrieve or parse secret {secret_name_arg}. Error: {e}")
        raise e


snowflake_login_secret_name = args.get('SNOWFLAKE_SECRET_NAME')
snowflake_url = args.get('SNOWFLAKE_URL')
snowflake_warehouse_name = args.get('SNOWFLAKE_WAREHOUSE_NAME')
snowflake_schema_name = args.get('SNOWFLAKE_SCHEMA_NAME')
snowflake_database_name = args.get('SNOWFLAKE_DATABASE_NAME')
snowflake_table_name = args.get('SNOWFLAKE_TABLE_NAME')

try:
    snowflake_user, snowflake_password = get_snowflake_credentials_from_secret(
        snowflake_login_secret_name)
except Exception as e:
    print("Failed to get Snowflake credentials. Exiting job.")
    sys.exit(f"Credential retrieval failed: {e}")

STOCK_TICKERS = [
    "AAPL", "MSFT", "AMZN", "GOOGL", "META", "TSLA", "NVDA", "JPM",
    "V", "PG", "UNH", "HD", "BAC", "XOM", "AVGO", "MA", "JNJ", "WMT",
    "CVX", "LLY", "MRK", "KO", "PEP", "ABBV", "COST", "MCD", "CRM",
    "TMO", "ABT", "ACN", "DHR", "CSCO", "NKE", "ADBE", "TXN", "AMD"
]
SECURITY_LIST = {ticker: Decimal(str(random.uniform(50.00, 500.00))).quantize(
    Decimal('0.01')) for ticker in STOCK_TICKERS}

ACCOUNT_LIST = [f'accnt{i:03d}' for i in range(1, 51)]
TIME_IN_FORCE_LIST = ["DAY", "GTC", "IOC",
                      "FOK", "GTD", "AT_THE_OPEN", "AT_THE_CLOSE"]
ORDER_INSTRUCTIONS_LIST = [
    "DISCLOSED_QUANTITY", "MINIMUM_QUANTITY", "ROUTE_TO_EXCHANGE",
    "ROUTE_TO_MARKET_MAKER", "ROUTE_TO_ECN", "PARTICIPATE_DONT_INITIATE",
    "STANDARD", "HELD", "NOT_HELD"
]
EXECUTION_INSTRUCTIONS_LIST = [
    "ALL_OR_NONE", "FILL_OR_KILL", "DO_NOT_INCREASE", "DO_NOT_REDUCE",
    "STANDARD", "ALLOW_PARTIAL_FILLS"
]
SIDES_LIST = ["BUY", "SELL", "BUY_TO_COVER", "SELL_SHORT"]


def generate_random_order():
    order_type = random.choice(['market', 'limit', 'stop'])
    security_id = random.choice(list(SECURITY_LIST.keys()))
    base_price = SECURITY_LIST[security_id]
    price, stop_price = None, None
    qty = random.randint(1, 200) * random.choice([1, 5, 10])

    if order_type == 'limit':
        price = (base_price * Decimal(str(random.uniform(0.95, 1.05)))
                 ).quantize(Decimal("0.01"))
    elif order_type == 'stop':
        stop_price = (
            base_price * Decimal(str(random.uniform(0.90, 1.10)))).quantize(Decimal("0.01"))
        if random.choice([True, False]):
            price = (stop_price * Decimal(str(random.uniform(0.99, 1.01)))
                     ).quantize(Decimal("0.01"))
            order_type = 'stop limit'

    order_instructions_val = random.choice(ORDER_INSTRUCTIONS_LIST)
    execution_instructions_val = random.choice(EXECUTION_INSTRUCTIONS_LIST)

    time_in_force_val = random.choice(TIME_IN_FORCE_LIST)

    if order_instructions_val == "FOK" or execution_instructions_val == "FILL_OR_KILL":
        time_in_force_val = "IOC"
        order_instructions_val = "FOK"
        execution_instructions_val = "FILL_OR_KILL"
    elif execution_instructions_val == "ALL_OR_NONE":
        order_instructions_val = "AON"

    if time_in_force_val == "FOK":
        order_instructions_val = "FOK"
        execution_instructions_val = "FILL_OR_KILL"

    return (
        order_type,
        security_id,
        qty,
        random.choice(SIDES_LIST),
        str(uuid.uuid4()),
        random.choice(ACCOUNT_LIST),
        price,
        stop_price,
        time_in_force_val,
        order_instructions_val,
        execution_instructions_val
    )


order_data = [generate_random_order() for _ in range(10000)]

schema = StructType([
    StructField(f"\"order_type\"", StringType(), True),
    StructField(f"\"security_id\"", StringType(), True),
    StructField(f"\"quantity\"", IntegerType(), True),
    StructField(f"\"side\"", StringType(), True),
    StructField(f"\"order_id\"", StringType(), True),
    StructField(f"\"account_id\"", StringType(), True),
    StructField(f"\"price\"", DecimalType(18, 2), True),
    StructField(f"\"stop_price\"", DecimalType(18, 2), True),
    StructField(f"\"time_in_force\"", StringType(), True),
    StructField(f"\"order_instructions\"", StringType(), True),
    StructField(f"\"execution_instructions\"", StringType(), True)
])

orders_df = spark.createDataFrame(data=order_data, schema=schema)
orders_dynamic_frame = DynamicFrame.fromDF(
    orders_df, glueContext, "orders_dynamic_frame_final")

snowflake_connection_options = {
    "sfUrl": snowflake_url,
    "sfUser": snowflake_user,
    "sfPassword": snowflake_password,
    "sfDatabase": f"\"{snowflake_database_name}\"",
    "sfSchema": f"\"{snowflake_schema_name}\"",
    "dbtable": f"\"{snowflake_table_name}\"",
    "sfWarehouse": f"\"{snowflake_warehouse_name}\"",
}

try:
    glueContext.write_dynamic_frame.from_options(
        frame=orders_dynamic_frame,
        connection_type="snowflake",
        connection_options=snowflake_connection_options
    )
except Exception as e:
    raise e

job.commit()