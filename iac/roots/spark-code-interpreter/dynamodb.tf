// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# DynamoDB table for chat history
module "chat_history_table" {
  source = "../../templates/modules/dynamodb"

  table_name = "${var.APP}-${var.ENV}-bedrock-chat-history-${data.aws_caller_identity.current.account_id}-${var.AWS_PRIMARY_REGION}"
  hash_key   = "UserId"
  range_key  = "SessionId"

  # No additional attributes needed beyond the key attributes
  attributes = []

  # No secondary indices needed
  local_secondary_indices  = []
  global_secondary_indices = []

  # No import configuration needed
  enable_import = false

  # Use AWS managed KMS key for DynamoDB (let AWS handle the default)
  dynamodb_kms_key_arn = null
}

# Output the DynamoDB table name
output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for chat history"
  value       = module.chat_history_table.name
}
