// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_ssoadmin_instances" "identity_center" {}

data "aws_kms_key" "ssm_kms_key" {

  key_id   = "alias/${var.SSM_KMS_KEY_ALIAS}"
}

locals {
  domain_id = data.aws_ssm_parameter.datazone_domain_id.value
  json_data = jsondecode(data.aws_ssm_parameter.user_mappings.value)

  # Extract only Project Owner
  project_owner_emails = flatten([
    for domain, groups in local.json_data : groups["Project Owner"]
  ])  # Taking all the Project Owner emails
}

data "aws_identitystore_user" "project_owners" {
  for_each = toset(nonsensitive(local.project_owner_emails))

  identity_store_id = data.aws_ssoadmin_instances.identity_center.identity_store_ids[0]
  alternate_identifier {
    unique_attribute {
      attribute_path  = "UserName"
      attribute_value = each.key
    }
  }
}

locals {
  project_owner_ids = [
    for email in nonsensitive(local.project_owner_emails) :
    data.aws_identitystore_user.project_owners[email].user_id
  ]
}

# Create Datazone Project for Producer
module "producer_project" {

  source = "../../../templates/modules/datazone-project/project"

  APP                       = var.APP
  ENV                       = var.ENV
  KMS_KEY                   = data.aws_kms_key.ssm_kms_key.arn
  USAGE                     = "Datazone"
  domain_id                 = local.domain_id
  project_name              = var.PROJECT_PRODUCER_NAME
  project_owner             = local.project_owner_ids[0]
  project_description       = var.PROJECT_PRODUCER_DESCRIPTION
  glossary_terms            = var.PROJECT_GLOSSARY
}

# Create Datazone Environment for Producer Project
module "producer_project_env" {

  source = "../../../templates/modules/datazone-project/environment"

  APP                       = var.APP
  ENV                       = var.ENV
  KMS_KEY                   = data.aws_kms_key.ssm_kms_key.arn
  USAGE                     = "Datazone"
  domain_id                 = local.domain_id
  project_id                = module.producer_project.project_id
  region                    = data.aws_region.current.name
  profile_name              = var.PRODUCER_PROFILE_NAME
  env_name                  = var.PRODUCER_ENV_NAME
  profile_description       = var.PRODUCER_PROFILE_DESCRIPTION
  account_id                = data.aws_caller_identity.current.account_id
  environment_blueprint_id  = data.aws_ssm_parameter.datalake_profile_id.value
  depends_on                = [ module.producer_project ]
}

# Create Datazone Datasource for Producer Project
module "producer_project_datasource" {

  source = "../../../templates/modules/datazone-project/datasource"

  APP                       = var.APP
  ENV                       = var.ENV
  KMS_KEY                   = data.aws_kms_key.ssm_kms_key.arn
  USAGE                     = "Datazone"
  domain_id                 = local.domain_id
  project_id                = module.producer_project.project_id
  datasource_name           = var.DATASOURCE_NAME
  datasource_type           = var.DATASOURCE_TYPE
  datasource_configuration  = var.GLUE_DATASOURCE_CONFIGURATION
  environment_id            = module.producer_project_env.environment_id
  depends_on                = [ module.producer_project_env ]
}

# Run Datasource start
resource "null_resource" "runProducerDataSource" {

  provisioner "local-exec" {
    command = <<-EOT
      aws datazone start-data-source-run \
        --domain-identifier "${local.domain_id}" \
        --data-source-identifier "${module.producer_project_datasource.datasource_id}" 
    EOT
  }
  depends_on = [ module.producer_project_datasource ]
}

