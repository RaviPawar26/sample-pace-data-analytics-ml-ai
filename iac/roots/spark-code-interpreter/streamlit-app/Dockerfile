# Use Amazon Linux 2023 as base image (comparable to al2023-ami-kernel-6.1-x86_64)
FROM public.ecr.aws/amazonlinux/amazonlinux:2023

# Set working directory
WORKDIR /app

# Install system dependencies for running the application
RUN dnf update -y && \
    dnf upgrade -y && \
    dnf groupinstall "Development Tools" -y && \
    dnf install -y --allowerasing \
    python3 \
    python3-pip \
    tar \
    gzip \
    openssl-devel \
    bzip2-devel \
    libffi-devel \
    wget \
    curl \
    git \
    tmux \
    && dnf clean all

# Create symbolic links for Python and pip
RUN ln -sf /usr/bin/python3 /usr/local/bin/python && \
    ln -sf /usr/bin/pip3 /usr/local/bin/pip

# Verify Python version
RUN python --version && pip --version

# Install critical dependencies first
RUN pip install python-dateutil setuptools wheel

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY bedrock-chat.py .
COPY function_calling_utils.py .
COPY pricing.json .
COPY config.json .

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws/

# Configure AWS region
RUN mkdir -p ~/.aws && \
    echo "[default]" > ~/.aws/config && \
    echo "region = us-east-1" >> ~/.aws/config

# Expose port 8501 for Streamlit
EXPOSE 8501

# Configure Streamlit
ENV STREAMLIT_SERVER_ADDRESS=0.0.0.0
ENV STREAMLIT_SERVER_PORT=8501
ENV STREAMLIT_SERVER_ENABLE_CORS=false
ENV STREAMLIT_SERVER_ENABLE_XSRF_PROTECTION=false

# Health check to ensure the application is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8501/_stcore/health || exit 1

# Copy entrypoint script
COPY entrypoint.sh .
RUN chmod +x /app/entrypoint.sh

# Set entry point to run the script that handles configuration and starts Streamlit
ENTRYPOINT ["/app/entrypoint.sh"]