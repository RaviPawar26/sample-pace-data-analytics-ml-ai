#!/bin/bash
# Entrypoint script for the Streamlit container
# This script sets up the environment and starts the Streamlit application

# Enable error handling
set -e

# Setup logging
LOG_FILE="/app/streamlit.log"
exec > >(tee -a ${LOG_FILE}) 2>&1

echo "=== Starting Streamlit container at $(date) ==="

# Debug: Print environment variables
echo "Environment variables:"
echo "AWS_ACCOUNT_ID: ${AWS_ACCOUNT_ID}"
echo "AWS_REGION: ${AWS_REGION}"
echo "APP: ${APP}"
echo "ENV: ${ENV}"

# Replace placeholders in config.json with actual values
echo "Updating configuration files..."
sed -i "s/ACCOUNT_ID/${AWS_ACCOUNT_ID}/g" /app/config.json
sed -i "s/REGION/${AWS_REGION}/g" /app/config.json
sed -i "s/APP/${APP}/g" /app/config.json
sed -i "s/ENV/${ENV}/g" /app/config.json

# Debug: Print the updated config.json
echo "Updated config.json:"
cat /app/config.json

# Create a virtual environment if needed for isolation (commented out as we're using system Python)
# echo "Setting up Python environment..."
# python -m venv /app/.venv
# source /app/.venv/bin/activate

# Verify Python and pip versions
echo "Python environment:"
python --version
pip --version

# Optional: Start in tmux session for better management (if running interactively)
if [ -t 0 ]; then
  echo "Starting Streamlit in tmux session..."
  # Check if tmux session exists
  if ! tmux has-session -t streamlit 2>/dev/null; then
    tmux new-session -d -s streamlit "cd /app && streamlit run bedrock-chat.py 2>&1 | tee -a ${LOG_FILE}"
    echo "Streamlit started in tmux session. Use 'docker exec -it <container> tmux attach -t streamlit' to connect."
    # Keep container running
    tail -f ${LOG_FILE}
  else
    echo "Tmux session already exists, attaching..."
    tmux attach -t streamlit
  fi
else
  # Start Streamlit application directly with logging when running as container entrypoint
  echo "Starting Streamlit application..."
  cd /app && streamlit run bedrock-chat.py 2>&1 | tee -a ${LOG_FILE}
fi