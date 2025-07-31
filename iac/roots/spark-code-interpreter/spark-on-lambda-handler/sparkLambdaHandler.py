import json
import traceback
import subprocess
import base64
import os
import boto3
import sys
import re
import tempfile
import logging
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("spark-lambda")

# Ensure all child loggers also log to CloudWatch
logging.getLogger().setLevel(logging.INFO)  # Set root logger to INFO level

class CodeExecutionError(Exception):
    pass

def local_code_executy(code_string, spark_configs):   
    logger.info("Creating temporary Python file for Spark execution")
    # Create temporary files
    with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as temp_file:
        temp_file_path = temp_file.name
        temp_file.write(code_string)
        logger.debug(f"Created temporary file at {temp_file_path}")

    output_file_path = '/tmp/output.json'
    log_file_path = '/tmp/spark_log.txt'

    spark_submit_args = [
        "spark-submit",
        "--conf", "spark.driver.extraJavaOptions=-Dlog4j.configuration=file:/opt/spark/conf/log4j.properties",
        "--conf", "spark.executor.extraJavaOptions=-Dlog4j.configuration=file:/opt/spark/conf/log4j.properties",
        # Add S3A filesystem configurations
        "--conf", "spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem",
        "--conf", "spark.hadoop.fs.s3a.aws.credentials.provider=com.amazonaws.auth.DefaultAWSCredentialsProviderChain",
        # Fix for IOStatisticsBinding issue
        "--conf", "spark.hadoop.fs.s3a.experimental.input.fadvise=sequential",
        "--conf", "spark.hadoop.fs.s3a.connection.maximum=100",
        "--conf", "spark.hadoop.fs.s3a.impl.disable.cache=true",
        "--conf", "spark.hadoop.fs.s3a.path.style.access=true",
        "--conf", "spark.hadoop.fs.s3a.committer.name=directory",
        "--conf", "spark.hadoop.fs.s3a.committer.staging.conflict-mode=append",
        "--conf", "spark.hadoop.fs.s3a.committer.staging.unique-filenames=true",
        "--conf", "spark.hadoop.fs.s3a.fast.upload=true",
        "--conf", "spark.hadoop.mapreduce.fileoutputcommitter.algorithm.version=2",
        # Additional configurations to fix IOStatisticsBinding error
        "--conf", "spark.driver.extraClassPath=/opt/spark/jars/*",
        "--conf", "spark.executor.extraClassPath=/opt/spark/jars/*",
        "--conf", "spark.hadoop.fs.s3a.bucket.all.committer.magic.enabled=true",
        "--conf", "spark.hadoop.fs.s3a.attempts.maximum=20",
        "--conf", "spark.hadoop.fs.s3a.connection.establish.timeout=5000",
        "--conf", "spark.hadoop.fs.s3a.connection.timeout=200000",
        "--conf", "spark.hadoop.fs.s3a.threads.max=20",
    ]
    if spark_configs:
        logger.info(f"Adding Spark configurations: {spark_configs}")
        for key, value in spark_configs.items():
            spark_submit_args.extend(["--conf", f"{key}={value}"])    
    spark_submit_args.append(temp_file_path)

    try:
        logger.info("Starting Spark job execution")
        
        # Use Popen instead of run to capture output in real-time
        process = subprocess.Popen(
            spark_submit_args,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,
            universal_newlines=True
        )
        
        # Open log file for writing
        with open(log_file_path, 'w') as log_file:
            # Process stdout and stderr in real-time using threads
            from threading import Thread
            from queue import Queue, Empty
            
            def enqueue_output(out, queue, prefix, log_file):
                for line in iter(out.readline, ''):
                    if line:
                        logger.info(f"{prefix}: {line.strip()}")
                        log_file.write(line)
                        queue.put(line)
                out.close()
            
            # Create queues for stdout and stderr
            stdout_queue = Queue()
            stderr_queue = Queue()
            
            # Start threads to read stdout and stderr
            stdout_thread = Thread(target=enqueue_output, args=(process.stdout, stdout_queue, "SPARK-STDOUT", log_file))
            stderr_thread = Thread(target=enqueue_output, args=(process.stderr, stderr_queue, "SPARK-STDERR", log_file))
            stdout_thread.daemon = True
            stderr_thread.daemon = True
            stdout_thread.start()
            stderr_thread.start()
            
            # Wait for process to complete
            process.wait()
            
            # Give threads a moment to finish processing any remaining output
            import time
            time.sleep(1)
        
        # Check if process completed successfully
        if process.returncode != 0:
            raise subprocess.CalledProcessError(process.returncode, spark_submit_args)
            
        logger.info(f"Spark execution logs written to {log_file_path}")

        # If execution was successful, read the output
        if os.path.exists(output_file_path):
            logger.info(f"Reading output from {output_file_path}")
            with open(output_file_path, 'r') as f:
                output = json.load(f)
            return output
        else:
            logger.error("Output file not found after Spark execution")
            raise CodeExecutionError("Output file not found. Execution may have failed without producing output.")

    except subprocess.CalledProcessError as e:
        logger.error("Spark job execution failed")
        error_message = parse_error(e.stdout, e.stderr, code_string, log_file_path)
        raise CodeExecutionError(error_message)

    finally:
        # Clean up temporary files
        logger.info("Cleaning up temporary files")
        for file_path in [temp_file_path, output_file_path]:
            if os.path.exists(file_path):
                os.remove(file_path)

def parse_error(stdout, stderr, code_string, log_file_path):
    logger.info("Parsing error details from Spark execution")
    error_message = "Execution Error:\n"

    # Add stdout if it exists
    if stdout:
        logger.debug("Adding stdout to error message")
        error_message += f"Standard Output:\n{stdout}\n\n"

    # Add stderr if it exists
    if stderr:
        logger.debug("Adding stderr to error message")
        error_message += f"Standard Error:\n{stderr}\n\n"

    # Look for Python tracebacks in stderr
    python_error_pattern = r'Traceback \(most recent call last\):(.*?)(?:\n\n|\Z)'
    match = re.search(python_error_pattern, stderr, re.DOTALL)

    if match:
        logger.info("Found Python traceback in error output")
        traceback = match.group(1).strip()
        error_message += f"Python Traceback:\n{traceback}\n\n"

        # Extract line number and error message
        line_match = re.search(r'File.*?line (\d+)', traceback)
        error_type_match = re.search(r'(\w+Error:.*?)(?:\n|$)', traceback)

        if line_match and error_type_match:
            line_no = int(line_match.group(1))
            error_type = error_type_match.group(1)
            logger.info(f"Error identified: {error_type} at line {line_no}")

            # Provide context around the error
            code_lines = code_string.split('\n')
            context_lines = 2
            start = max(0, line_no - 1 - context_lines)
            end = min(len(code_lines), line_no + context_lines)

            context = "\n".join([f"{'-> ' if i == line_no else '   '}{i}: {line}" 
                                 for i, line in enumerate(code_lines[start:end], start=start+1)])

            error_message += f"Error on line {line_no}:\n{context}\n\nError Type: {error_type}\n\n"

    # Add contents of log file if it exists
    if os.path.exists(log_file_path):
        with open(log_file_path, 'r') as log_file:
            log_contents = log_file.read()
            error_message += f"Log File Contents:\n{log_contents}\n\n"

    return error_message
    
def execute_function_string(input_code, trial, bucket, key_prefix, spark_config):
    """
    Execute a given Python code string, potentially modifying dataset paths to use S3. 
    If it's the first trial (trial < 1) and the S3 bucket/prefix are not already in the code:
       - Replaces local dataset references with S3 URIs.

    Parameters:
    input_code (dict): A dictionary containing the following keys:
        - 'code' (str): The Python code to be executed.
        - 'dataset_name' (str or list, optional): Name(s) of the dataset(s) used in the code.
    trial (int): A counter for execution attempts, used to determine if S3 paths should be injected.
    bucket (str): The name of the S3 bucket where datasets are stored.
    key_prefix (str): The S3 key prefix (folder path) where datasets are located within the bucket.

    Returns:
    The result of executing the code using the local_code_executy function.

    """
    code_string = input_code['code']
    dataset_names = input_code.get('dataset_name', [])
    if isinstance(dataset_names, str):
        dataset_names = [d.strip() for d in dataset_names.strip('[]').split(',')]
    
    # Log the code being executed
    logger.info(f"Executing Spark code with datasets: {dataset_names}")
    logger.debug(f"Code to execute:\n{code_string}")
    
    # Add cluster configuration to spark_config
    return local_code_executy(code_string, spark_config)


def put_obj_in_s3_bucket_(docs, bucket, key_prefix):
    """Uploads a file to an S3 bucket and returns the S3 URI of the uploaded object.
    Args:
       docs (str): The local file path of the file to upload to S3.
       bucket (str): S3 bucket name,
       key_prefix (str): S3 key prefix.
   Returns:
       str: The S3 URI of the uploaded object, in the format "s3://{bucket_name}/{file_path}".
    """
    S3 = boto3.client('s3')
    try:
        if isinstance(docs,str):
            file_name=os.path.basename(docs)
            file_path=f"{key_prefix}/{docs}"
            logger.info(f"Uploading file from /tmp/{docs} to s3://{bucket}/{file_path}")
            S3.upload_file(f"/tmp/{docs}", bucket, file_path)
            logger.info(f"Successfully uploaded file to s3://{bucket}/{file_path}")
        else:
            file_name=os.path.basename(docs.name)
            file_path=f"{key_prefix}/{file_name}"
            logger.info(f"Uploading file {file_name} to s3://{bucket}/{file_path}")
            S3.put_object(Body=docs.read(),Bucket=bucket, Key=file_path)
            logger.info(f"Successfully uploaded file to s3://{bucket}/{file_path}")           
        return f"s3://{bucket}/{file_path}"
    except Exception as e:
        logger.error(f"Error uploading file to S3: {str(e)}")
        raise e



def lambda_handler(event, context):
    try:
        logger.info("Received request to run Spark job")
        input_data = event['body']
        logger.info(f"Input data: {input_data}")
        iterate = input_data.get('iterate', 0)
        bucket=input_data.get('bucket','')
        s3_file_path=input_data.get('file_path','')        
        spark_config = input_data.get('config', '')
        
        logger.info(f"Job parameters - Bucket: {bucket}, Path: {s3_file_path}, Iterate: {iterate}")
        logger.info(f"Spark config: {spark_config}")
        
        result = execute_function_string(input_data, iterate, bucket, s3_file_path, spark_config)
        image_holder = []
        plotly_holder = []
        
        if isinstance(result, dict):
            logger.info("Processing Spark job results")
            for item, value in result.items():
                if "image" in item and value is not None: # upload PNG files to S3
                    logger.info(f"Processing image output: {item}")
                    if isinstance(value, list):
                        logger.info(f"Found {len(value)} images to upload")
                        for img in value:
                            image_path_s3 = put_obj_in_s3_bucket_(img, bucket, s3_file_path)
                            image_holder.append(image_path_s3)
                            logger.info(f"Added image to results: {image_path_s3}")                            
                    else:                        
                        image_path_s3 = put_obj_in_s3_bucket_(value, bucket, s3_file_path)
                        image_holder.append(image_path_s3)
                        logger.info(f"Added image to results: {image_path_s3}")
                if "plotly-files" in item and value is not None: # Upload plotly objects to s3
                    logger.info(f"Processing plotly output: {item}")
                    if isinstance(value, list):
                        logger.info(f"Found {len(value)} plotly files to upload")
                        for img in value:
                            image_path_s3 = put_obj_in_s3_bucket_(img, bucket, s3_file_path)
                            plotly_holder.append(image_path_s3)
                            logger.info(f"Added plotly to results: {image_path_s3}")                            
                    else:                        
                        image_path_s3 = put_obj_in_s3_bucket_(value, bucket, s3_file_path)
                        plotly_holder.append(image_path_s3)
                        logger.info(f"Added plotly to results: {image_path_s3}")
        
        tool_result = {
            "result": result,            
            "image_dict": image_holder,
            "plotly": plotly_holder
        }
        logger.info(tool_result)
        logger.info("Spark job completed successfully")        
        
        return {
            'statusCode': 200,
            'body': json.dumps(tool_result)
        }
        
    except Exception as e:
        logger.error(f"Lambda handler encountered an error: {str(e)}")
        logger.error(traceback.format_exc())
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
