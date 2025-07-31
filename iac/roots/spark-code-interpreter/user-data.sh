#!/bin/bash
# Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# Set up logging
exec > >(tee /var/log/user-data.log) 2>&1
echo "Starting user data script at $(date)"

# Update and install packages
yum update -y
yum install -y docker

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && ./aws/install && rm -rf awscliv2.zip aws/

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm && rm -f ./amazon-cloudwatch-agent.rpm

# Start Docker
systemctl start docker && systemctl enable docker
usermod -a -G docker ec2-user

# ECR login and pull image
export AWS_DEFAULT_REGION=${AWS_REGION}
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
docker pull ${STREAMLIT_IMAGE_URI}

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Run Streamlit container
docker run -d --name streamlit-app --restart unless-stopped -p 8501:8501\
    -e AWS_DEFAULT_REGION=${AWS_REGION} \
    -e AWS_REGION=${AWS_REGION} \
    -e AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID} \
    -e APP=${APP} \
    -e ENV=${ENV} \
    --log-driver=awslogs --log-opt awslogs-group="/aws/ec2/${APP}-${ENV}-streamlit" \
    --log-opt awslogs-region=${AWS_REGION} --log-opt awslogs-create-group=true \
    ${STREAMLIT_IMAGE_URI}

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "agent": {"metrics_collection_interval": 60, "run_as_user": "cwagent"},
    "metrics": {
        "namespace": "CWAgent",
        "metrics_collected": {
            "cpu": {"measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"], "metrics_collection_interval": 60},
            "disk": {"measurement": ["used_percent"], "metrics_collection_interval": 60, "resources": ["*"]},
            "mem": {"measurement": ["mem_used_percent"], "metrics_collection_interval": 60}
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {"file_path": "/var/log/user-data.log", "log_group_name": "/aws/ec2/${APP}-${ENV}-user-data", "log_stream_name": "{instance_id}/user-data"},
                    {"file_path": "/var/log/messages", "log_group_name": "/aws/ec2/${APP}-${ENV}-system", "log_stream_name": "{instance_id}/messages"}
                ]
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
systemctl enable amazon-cloudwatch-agent

# Create log groups
aws logs create-log-group --log-group-name "/aws/ec2/${APP}-${ENV}-streamlit" --region ${AWS_REGION} 2>/dev/null || true
aws logs create-log-group --log-group-name "/aws/ec2/${APP}-${ENV}-system" --region ${AWS_REGION} 2>/dev/null || true
aws logs create-log-group --log-group-name "/aws/ec2/${APP}-${ENV}-user-data" --region ${AWS_REGION} 2>/dev/null || true

# Health monitoring script
cat > /usr/local/bin/health-check.sh << 'EOF'
#!/bin/bash
if ! docker ps | grep -q streamlit-app; then
    echo "$(date): Container down, restarting..."
    
    # Get AWS account ID
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    
    docker start streamlit-app || {
        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
        docker rm streamlit-app 2>/dev/null || true
        docker run -d --name streamlit-app --restart unless-stopped -p 8501:8501 \
            -e AWS_DEFAULT_REGION=${AWS_REGION} \
            -e AWS_REGION=${AWS_REGION} \
            -e AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID} \
            -e APP=${APP} \
            -e ENV=${ENV} \
            --log-driver=awslogs --log-opt awslogs-group="/aws/ec2/${APP}-${ENV}-streamlit" \
            --log-opt awslogs-region=${AWS_REGION} --log-opt awslogs-create-group=true \
            ${STREAMLIT_IMAGE_URI}
    }
fi
EOF
chmod +x /usr/local/bin/health-check.sh
echo "*/5 * * * * /usr/local/bin/health-check.sh" | crontab -

# Deployment update script
cat > /usr/local/bin/update-streamlit.sh << 'EOF'
#!/bin/bash
echo "$(date): Starting Streamlit container update..."

# Stop and remove current container
docker stop streamlit-app 2>/dev/null || true
docker rm streamlit-app 2>/dev/null || true

# Login to ECR and pull latest image
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
docker pull ${STREAMLIT_IMAGE_URI}

# Remove old images to save space
docker image prune -f

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Start new container
docker run -d --name streamlit-app --restart unless-stopped -p 8501:8501 \
    -e AWS_DEFAULT_REGION=${AWS_REGION} \
    -e AWS_REGION=${AWS_REGION} \
    -e AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID} \
    -e APP=${APP} \
    -e ENV=${ENV} \
    --log-driver=awslogs --log-opt awslogs-group="/aws/ec2/${APP}-${ENV}-streamlit" \
    --log-opt awslogs-region=${AWS_REGION} --log-opt awslogs-create-group=true \
    ${STREAMLIT_IMAGE_URI}

echo "$(date): Streamlit container update completed"
echo "$(date): $(docker ps | grep streamlit-app)"
EOF
chmod +x /usr/local/bin/update-streamlit.sh

echo "Setup completed at $(date)"