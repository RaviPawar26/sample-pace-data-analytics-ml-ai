# Use AWS Lambda Python 3.12 image as base for latest performance and features
FROM public.ecr.aws/lambda/python:3.12

# Setting the compatible versions of libraries
ARG HADOOP_VERSION=3.3.6
ARG AWS_SDK_VERSION=1.12.261
ARG PYSPARK_VERSION=3.5.0

ARG FRAMEWORK
ARG DELTA_FRAMEWORK_VERSION=2.2.0
ARG HUDI_FRAMEWORK_VERSION=0.12.2
ARG ICEBERG_FRAMEWORK_VERSION=3.3_2.12
ARG ICEBERG_FRAMEWORK_SUB_VERSION=1.0.0
ARG DEEQU_FRAMEWORK_VERSION=2.0.3-spark-3.3

ARG AWS_REGION
ENV AWS_REGION=${AWS_REGION}

# Perform system updates and install dependencies
RUN dnf update -y && \
    dnf install -y wget unzip java-1.8.0-openjdk java-1.8.0-openjdk-devel python3-setuptools && \
    pip install --upgrade pip && \
    pip install setuptools wheel && \
    pip install pyspark==$PYSPARK_VERSION boto3 && \
    dnf clean all

# Set JAVA_HOME environment variable directly
ENV JAVA_HOME=/usr/lib/jvm/jre-1.8.0-openjdk

# Copy and install Python requirements
COPY requirements.txt ${LAMBDA_TASK_ROOT}/
RUN pip install -r ${LAMBDA_TASK_ROOT}/requirements.txt

RUN echo "$FRAMEWORK" | grep -q "DEEQU" && \
    pip install --no-deps pydeequ && \
    pip install pandas && \
    dnf clean all && \
    echo "DEEQU found in FRAMEWORK" || \
    echo "DEEQU not found in FRAMEWORK"


# Set environment variables for PySpark
ENV SPARK_HOME="/var/lang/lib/python3.12/site-packages/pyspark"
ENV SPARK_VERSION=3.5.0
ENV PATH=$PATH:$SPARK_HOME/bin
ENV PATH=$PATH:$SPARK_HOME/sbin
ENV PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.9.7-src.zip:/home/glue_functions:$PYTHONPATH
ENV PATH=$SPARK_HOME/python:$PATH

COPY download_jars.sh /tmp

RUN chmod +x /tmp/download_jars.sh && \
    /tmp/download_jars.sh $FRAMEWORK $SPARK_HOME $HADOOP_VERSION $AWS_SDK_VERSION $DELTA_FRAMEWORK_VERSION $HUDI_FRAMEWORK_VERSION $ICEBERG_FRAMEWORK_VERSION $ICEBERG_FRAMEWORK_SUB_VERSION $DEEQU_FRAMEWORK_VERSION

# Add Java to PATH
ENV PATH=${PATH}:${JAVA_HOME}/bin

# Verify Java installation
RUN java -version

# Setting  up the ENV vars for local code, in AWS LAmbda you have to set Input_path and Output_path
ENV INPUT_PATH=""
ENV OUTPUT_PATH=""
ENV CUSTOM_SQL=""

# Find all spark-class files in the container
RUN find / -name "spark-class" -type f 2>/dev/null || echo "No spark-class files found"

# Check if spark-class exists and show its content before copying
RUN ls -la $SPARK_HOME/bin/ || echo "Spark bin directory not found"
RUN if [ -f "$SPARK_HOME/bin/spark-class" ]; then echo "Original spark-class:"; cat $SPARK_HOME/bin/spark-class; else echo "Original spark-class not found"; fi

# Copy our custom spark-class script and make it executable
COPY spark-class $SPARK_HOME/bin/
RUN chmod 755 $SPARK_HOME/bin/spark-class

# Verify the spark-class script was copied correctly
RUN echo "Custom spark-class after copying:"
RUN cat $SPARK_HOME/bin/spark-class

# Make sure our custom spark-class is the one being used
RUN ln -sf $SPARK_HOME/bin/spark-class /usr/local/bin/spark-class
# Check if the symlink was created successfully
RUN ls -la /usr/local/bin/spark-class

# Copy log4j properties file
COPY log4j.properties $SPARK_HOME/conf/

# Copy the Pyspark script to container
COPY sparkLambdaHandler.py ${LAMBDA_TASK_ROOT}

# Make sure the handler file is executable
RUN chmod 755 ${LAMBDA_TASK_ROOT}/sparkLambdaHandler.py

# Set the correct CMD format for Lambda
CMD [ "sparkLambdaHandler.lambda_handler" ]