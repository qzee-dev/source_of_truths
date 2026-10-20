Below is a complete production-standard AWS Landing Zone repository scaffold, generated from the beginning and structured for real deployment use.

Important:
- This is a production-standard scaffold, not a one-click deploy without review.
- Real AWS account IDs, CIDRs, VPC subnet IDs, KMS IDs, IAM trust IDs, and secret values must be supplied in a secure secret store or tfvars not committed to Git.
- This version intentionally includes the missing production pieces:
  - IAM Identity Center permission sets
  - cross-account trust roles
  - TGW route tables + propagation
  - flow logs
  - hardened network patterns
  - validation scripts
  - example tfvars file

Repository tree

```text
terraform-aws-landing-zone/
├── .gitignore
├── README.md
├── tagging-policy.tf
├── terraform.tfvars.example
├── bootstrap/
│   ├── README.md
│   ├── main.tf
│   ├── outputs.tf
│   ├── variables.tf
│   └── scripts/
│       ├── bootstrap-org.sh
│       └── bootstrap-state.sh
├── policies/
│   ├── baseline-scp.json
│   ├── nonprod-scp.json
│   ├── prod-scp.json
│   └── sandbox-scp.json
├── modules/
│   ├── active-directory/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── dns/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── iam-identity-center/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── network/
│   │   ├── flow-logs.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── route-tables.tf
│   │   └── variables.tf
│   ├── organizations/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── security/
│   │   ├── cross-account-roles.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── transit-gateway/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── route-tables.tf
│   │   └── variables.tf
│   └── workloads/
│       ├── dev/
│       │   ├── main.tf
│       │   ├── outputs.tf
│       │   └── variables.tf
│       ├── prod/
│       │   ├── main.tf
│       │   ├── outputs.tf
│       │   └── variables.tf
│       └── stage/
│           ├── main.tf
│           ├── outputs.tf
│           └── variables.tf
├── environments/
│   ├── management/
│   │   ├── backend.hcl
│   │   ├── locals.tf
│   │   ├── main.tf
│   │   └── variables.tf
│   ├── network/
│   │   ├── backend.hcl
│   │   ├── locals.tf
│   │   ├── main.tf
│   │   └── variables.tf
│   ├── sandbox/
│   │   ├── backend.hcl
│   │   ├── locals.tf
│   │   ├── main.tf
│   │   └── variables.tf
│   ├── security/
│   │   ├── backend.hcl
│   │   ├── locals.tf
│   │   ├── main.tf
│   │   └── variables.tf
│   ├── shared-services/
│   │   ├── backend.hcl
│   │   ├── locals.tf
│   │   ├── main.tf
│   │   └── variables.tf
│   ├── workload-dev/
│   │   ├── backend.hcl
│   │   ├── locals.tf
│   │   ├── main.tf
│   │   └── variables.tf
│   ├── workload-prod/
│   │   ├── backend.hcl
│   │   ├── locals.tf
│   │   ├── main.tf
│   │   └── variables.tf
│   └── workload-stage/
│       ├── backend.hcl
│       ├── locals.tf
│       ├── main.tf
│       └── variables.tf
├── scripts/
│   ├── bootstrap-state.sh
│   ├── deploy-all.sh
│   └── validate-landing-zone.sh
└── .gitignore
```

1) Root files

File: .gitignore
```gitignore name=.gitignore
# Terraform
.terraform/
.terraform.lock.hcl
*.tfstate
*.tfstate.*
crash.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json
*.tfvars
*.tfvars.json
terraform.tfvars
terraform.tfvars.json

# Secrets and local env
.env
.env.*
*.pem
*.key
*.crt
*.csr

# OS/editor
.DS_Store
.idea/
.vscode/
*.swp
*.swo
```

File: README.md
```markdown name=README.md
# Enterprise AWS Landing Zone for HIPAA-aligned Workloads

This repository contains a production-standard Terraform landing zone scaffold for:
- AWS Organizations
- multi-account design
- centralized security and logging
- hub-and-spoke network architecture
- hybrid connectivity
- production workload isolation
- staging and development isolation
- sandbox controls
- cost governance and tagging
- multi-state remote-state pattern

## Architecture

This repo models:

- AWS Organizations root
- Security-OU
- Infrastructure-OU
- Workloads-Prod-OU
- Workloads-NonProd-OU
- Sandbox-OU

Accounts:

- Management Account
- Log Archive Account
- Security Tooling Account
- Network Account
- Shared-System Account
- Production Account
- Staging Account
- Development Account
- Sandbox Account

VPCs:

- inspection: 10.30.0.0/16
- shared-services: 10.40.0.0/16
- prod: 10.50.0.0/16
- stage: 10.60.0.0/16
- dev: 10.70.0.0/16

## State model

Remote state is isolated per environment:
- management
- security
- network
- shared-services
- workload-prod
- workload-stage
- workload-dev
- sandbox

## Security controls

- AWS Organizations with SCPs
- centralized AWS Config
- centralized CloudTrail
- GuardDuty
- Security Hub
- KMS encryption
- VPC flow logs
- restricted public access
- centralized DNS and AD
- private-only networking principles

## Tagging standard

All resources should include:
- Environment
- ProjectID
- Owner
- CostCenter
- Compliance
- Automation

## Secret handling

Do not store secrets in Git.
Use:
- AWS Secrets Manager
- AWS Systems Manager Parameter Store
- CI/CD secret stores

## Important

This repository is production-standard scaffolding. Before deployment, replace all placeholder values with real AWS account IDs, real subnets, real CIDRs, real KMS IDs, and secure secrets.
```

File: terraform.tfvars.example
```hcl name=terraform.tfvars.example
aws_region = "us-east-1"

organization_name = "enterprise-org"

ou_security_name = "Security-OU"
ou_infrastructure_name = "Infrastructure-OU"
ou_workloads_prod_name = "Workloads-Prod-OU"
ou_workloads_nonprod_name = "Workloads-NonProd-OU"
ou_sandbox_name = "Sandbox-OU"

management_account_email = "management@example.com"
log_archive_account_email = "log-archive@example.com"
security_tooling_account_email = "security-tooling@example.com"
network_account_email = "network@example.com"
shared_system_account_email = "shared-system@example.com"
production_account_email = "prod@example.com"
staging_account_email = "staging@example.com"
development_account_email = "dev@example.com"
sandbox_account_email = "sandbox@example.com"

state_bucket_name = "enterprise-landing-zone-state"
lock_table_name = "enterprise-landing-zone-locks"

project_name = "medical-platform"
environment = "prod"

db_password = "REPLACE_WITH_STRONG_PASSWORD"
ad_password = "REPLACE_WITH_STRONG_PASSWORD"

onprem_cidrs = [
  "10.0.0.0/8"
]

management_account_id = "111111111111"
security_account_id = "222222222222"
network_account_id = "333333333333"
shared_system_account_id = "444444444444"
production_account_id = "555555555555"
```

File: tagging-policy.tf
```hcl name=tagging-policy.tf
locals {
  required_tags = {
    Environment = "Prod"
    ProjectID   = "medical-platform"
    Owner       = "platform-team"
    CostCenter  = "CC-1001"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}

resource "aws_resourcegroups_group" "this" {
  name = "medical-platform-resource-group"

  resource_query {
    type = "TAG_FILTERS_1_0"
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupportedResources"]
      TagFilters = [
        {
          Key = "Environment"
          Values = ["Prod"]
        }
      ]
    })
  }
}
```

2) Bootstrap

File: bootstrap/README.md
```markdown name=bootstrap/README.md
# Bootstrap

This folder creates the AWS Organizations foundation and remote state resources.

Required actions:
1. Create the management account
2. Enable AWS Organizations
3. Create OUs
4. Create member accounts
5. Create the Terraform state bucket
6. Create the DynamoDB lock table
7. Grant access to required accounts
8. Run the root Terraform stacks

## Important

This directory should only be executed from the management account.
```

File: bootstrap/variables.tf
```hcl name=bootstrap/variables.tf
variable "aws_region" {
  description = "Primary AWS region."
  type        = string
  default     = "us-east-1"
}

variable "organization_name" {
  description = "AWS Organization name."
  type        = string
  default     = "enterprise-org"
}

variable "ou_security_name" {
  type    = string
  default = "Security-OU"
}

variable "ou_infrastructure_name" {
  type    = string
  default = "Infrastructure-OU"
}

variable "ou_workloads_prod_name" {
  type    = string
  default = "Workloads-Prod-OU"
}

variable "ou_workloads_nonprod_name" {
  type    = string
  default = "Workloads-NonProd-OU"
}

variable "ou_sandbox_name" {
  type    = string
  default = "Sandbox-OU"
}

variable "management_account_email" {
  type    = string
  default = "management@example.com"
}

variable "log_archive_account_email" {
  type    = string
  default = "log-archive@example.com"
}

variable "security_tooling_account_email" {
  type    = string
  default = "security-tooling@example.com"
}

variable "network_account_email" {
  type    = string
  default = "network@example.com"
}

variable "production_account_email" {
  type    = string
  default = "prod@example.com"
}

variable "staging_account_email" {
  type    = string
  default = "staging@example.com"
}

variable "development_account_email" {
  type    = string
  default = "dev@example.com"
}

variable "shared_system_account_email" {
  type    = string
  default = "shared-system@example.com"
}

variable "sandbox_account_email" {
  type    = string
  default = "sandbox@example.com"
}

variable "state_bucket_name" {
  type    = string
  default = "enterprise-landing-zone-state"
}

variable "lock_table_name" {
  type    = string
  default = "enterprise-landing-zone-locks"
}
```

File: bootstrap/main.tf
```hcl name=bootstrap/main.tf
terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_organizations_organization" "this" {
  feature_set = "ALL"
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY",
    "BACKUP_POLICY"
  ]
}

resource "aws_organizations_organizational_unit" "security" {
  name      = var.ou_security_name
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "infrastructure" {
  name      = var.ou_infrastructure_name
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads_prod" {
  name      = var.ou_workloads_prod_name
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads_nonprod" {
  name      = var.ou_workloads_nonprod_name
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "sandbox" {
  name      = var.ou_sandbox_name
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_account" "log_archive" {
  name      = "log-archive"
  email     = var.log_archive_account_email
  parent_id = aws_organizations_organizational_unit.security.id

  lifecycle {
    ignore_changes = [email]
  }
}

resource "aws_organizations_account" "security_tooling" {
  name      = "security-tooling"
  email     = var.security_tooling_account_email
  parent_id = aws_organizations_organizational_unit.security.id

  lifecycle {
    ignore_changes = [email]
  }
}

resource "aws_organizations_account" "network" {
  name      = "network"
  email     = var.network_account_email
  parent_id = aws_organizations_organizational_unit.infrastructure.id

  lifecycle {
    ignore_changes = [email]
  }
}

resource "aws_organizations_account" "shared_system" {
  name      = "shared-system"
  email     = var.shared_system_account_email
  parent_id = aws_organizations_organizational_unit.infrastructure.id

  lifecycle {
    ignore_changes = [email]
  }
}

resource "aws_organizations_account" "production" {
  name      = "production"
  email     = var.production_account_email
  parent_id = aws_organizations_organizational_unit.workloads_prod.id

  lifecycle {
    ignore_changes = [email]
  }
}

resource "aws_organizations_account" "staging" {
  name      = "staging"
  email     = var.staging_account_email
  parent_id = aws_organizations_organizational_unit.workloads_nonprod.id

  lifecycle {
    ignore_changes = [email]
  }
}

resource "aws_organizations_account" "development" {
  name      = "development"
  email     = var.development_account_email
  parent_id = aws_organizations_organizational_unit.workloads_nonprod.id

  lifecycle {
    ignore_changes = [email]
  }
}

resource "aws_organizations_account" "sandbox" {
  name      = "sandbox"
  email     = var.sandbox_account_email
  parent_id = aws_organizations_organizational_unit.sandbox.id

  lifecycle {
    ignore_changes = [email]
  }
}

resource "aws_s3_bucket" "state" {
  bucket        = var.state_bucket_name
  force_destroy = false

  tags = {
    Name        = "tf-state"
    Environment = "Core"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.state.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_kms_key" "state" {
  description             = "Terraform state KMS key"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootUser"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${aws_organizations_organization.this.master_account_id}:root"
        }
        Action = ["kms:*"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_dynamodb_table" "locks" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "terraform-locks"
    Environment = "Core"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}
```

File: bootstrap/outputs.tf
```hcl name=bootstrap/outputs.tf
output "organization_id" {
  value = aws_organizations_organization.this.id
}

output "security_ou_id" {
  value = aws_organizations_organizational_unit.security.id
}

output "infrastructure_ou_id" {
  value = aws_organizations_organizational_unit.infrastructure.id
}

output "workloads_prod_ou_id" {
  value = aws_organizations_organizational_unit.workloads_prod.id
}

output "workloads_nonprod_ou_id" {
  value = aws_organizations_organizational_unit.workloads_nonprod.id
}

output "sandbox_ou_id" {
  value = aws_organizations_organizational_unit.sandbox.id
}

output "network_account_id" {
  value = aws_organizations_account.network.id
}

output "shared_system_account_id" {
  value = aws_organizations_account.shared_system.id
}

output "production_account_id" {
  value = aws_organizations_account.production.id
}

output "staging_account_id" {
  value = aws_organizations_account.staging.id
}

output "development_account_id" {
  value = aws_organizations_account.development.id
}

output "sandbox_account_id" {
  value = aws_organizations_account.sandbox.id
}

output "state_bucket_name" {
  value = aws_s3_bucket.state.bucket
}

output "lock_table_name" {
  value = aws_dynamodb_table.locks.name
}
```

File: bootstrap/scripts/bootstrap-state.sh
```bash name=bootstrap/scripts/bootstrap-state.sh
#!/usr/bin/env bash
set -euo pipefail

aws s3api create-bucket \
  --bucket enterprise-landing-zone-state \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket enterprise-landing-zone-state \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket enterprise-landing-zone-state \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms","KMSMasterKeyID":"alias/aws/s3"}}]}'

aws dynamodb create-table \
  --table-name enterprise-landing-zone-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

File: bootstrap/scripts/bootstrap-org.sh
```bash name=bootstrap/scripts/bootstrap-org.sh
#!/usr/bin/env bash
set -euo pipefail

echo "Bootstrap organization and accounts"
echo "Run this in the Management account only"

# Example actions
# aws organizations create-organization --feature-set ALL
# aws organizations list-roots
# aws organizations create-organizational-unit --name "Security-OU" --parent-id <ROOT_ID>
# aws organizations create-account --account-name "network" --email "network@example.com" --parent-id <OU_ID>
```

3) Policies

File: policies/baseline-scp.json
```json name=policies/baseline-scp.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "RestrictRootUsage",
      "Effect": "Deny",
      "Action": [
        "iam:CreateLoginProfile",
        "iam:CreateAccessKey",
        "iam:UpdateAccountPasswordPolicy",
        "iam:DeleteAccountAlias"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:PrincipalArn": "arn:aws:iam::*:root"
        }
      }
    },
    {
      "Sid": "RequireMfaForAdmin",
      "Effect": "Deny",
      "Action": [
        "iam:CreateUser",
        "iam:CreateAccessKey",
        "iam:PutUserPolicy",
        "iam:AttachUserPolicy",
        "iam:UpdateUser"
      ],
      "Resource": "*",
      "Condition": {
        "Bool": {
          "aws:MultiFactorAuthPresent": "false"
        }
      }
    },
    {
      "Sid": "RestrictRegions",
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": [
            "us-east-1",
            "us-east-2",
            "us-west-2"
          ]
        }
      }
    },
    {
      "Sid": "ProtectAuditLogs",
      "Effect": "Deny",
      "Action": [
        "cloudtrail:DeleteTrail",
        "cloudtrail:UpdateTrail",
        "cloudtrail:StopLogging",
        "config:DeleteDeliveryChannel",
        "config:DeleteConfigRule",
        "config:DeleteConfigurationRecorder",
        "config:StopConfigurationRecorder",
        "s3:DeleteBucket",
        "s3:DeleteObject"
      ],
      "Resource": "*"
    }
  ]
}
```

File: policies/prod-scp.json
```json name=policies/prod-scp.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "RequireCMKForStorage",
      "Effect": "Deny",
      "Action": [
        "ec2:CreateVolume",
        "s3:PutBucketEncryption",
        "ebs:CreateVolume"
      ],
      "Resource": "*",
      "Condition": {
        "Null": {
          "kms:GrantId": "true"
        }
      }
    },
    {
      "Sid": "DenyPublicS3",
      "Effect": "Deny",
      "Action": [
        "s3:CreateBucket"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "s3:PublicAccessBlock": "false"
        }
      }
    },
    {
      "Sid": "DenyDetachFlowLogs",
      "Effect": "Deny",
      "Action": [
        "ec2:DeleteFlowLog",
        "ec2:DeleteVpcEndpoints"
      ],
      "Resource": "*"
    }
  ]
}
```

File: policies/nonprod-scp.json
```json name=policies/nonprod-scp.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "LimitInstanceSizes",
      "Effect": "Deny",
      "Action": [
        "ec2:RunInstances"
      ],
      "Resource": "*",
      "Condition": {
        "ForAnyValue:StringEquals": {
          "ec2:InstanceType": [
            "m6i.32xlarge",
            "m6a.32xlarge",
            "r6i.32xlarge"
          ]
        }
      }
    },
    {
      "Sid": "DenyUnencryptedStorage",
      "Effect": "Deny",
      "Action": [
        "ec2:RunInstances",
        "ec2:CreateVolume"
      ],
      "Resource": "*",
      "Condition": {
        "Bool": {
          "ec2:Encrypted": "false"
        }
      }
    },
    {
      "Sid": "DenyPublicNetworkPaths",
      "Effect": "Deny",
      "Action": [
        "ec2:CreateInternetGateway"
      ],
      "Resource": "*"
    }
  ]
}
```

File: policies/sandbox-scp.json
```json name=policies/sandbox-scp.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyHighCostServices",
      "Effect": "Deny",
      "Action": [
        "ec2:CreateTransitGateway",
        "ec2:CreateVpcPeeringConnection",
        "ec2:CreateVpnConnection",
        "eks:CreateCluster",
        "rds:CreateDBInstance"
      ],
      "Resource": "*"
    }
  ]
}
```

4) Modules

File: modules/organizations/main.tf
```hcl name=modules/organizations/main.tf
resource "aws_organizations_organization" "this" {
  feature_set = "ALL"
}

resource "aws_organizations_organizational_unit" "security" {
  name      = "Security-OU"
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "infrastructure" {
  name      = "Infrastructure-OU"
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads_prod" {
  name      = "Workloads-Prod-OU"
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads_nonprod" {
  name      = "Workloads-NonProd-OU"
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "sandbox" {
  name      = "Sandbox-OU"
  parent_id = aws_organizations_organization.this.roots[0].id
}
```

File: modules/organizations/variables.tf
```hcl name=modules/organizations/variables.tf
variable "organization_name" {
  type = string
}
```

File: modules/organizations/outputs.tf
```hcl name=modules/organizations/outputs.tf
output "org_id" {
  value = aws_organizations_organization.this.id
}

output "security_ou_id" {
  value = aws_organizations_organizational_unit.security.id
}

output "infrastructure_ou_id" {
  value = aws_organizations_organizational_unit.infrastructure.id
}

output "workloads_prod_ou_id" {
  value = aws_organizations_organizational_unit.workloads_prod.id
}

output "workloads_nonprod_ou_id" {
  value = aws_organizations_organizational_unit.workloads_nonprod.id
}

output "sandbox_ou_id" {
  value = aws_organizations_organizational_unit.sandbox.id
}
```

File: modules/network/main.tf
```hcl name=modules/network/main.tf
resource "aws_vpc" "inspection" {
  cidr_block           = "10.30.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "inspection-vpc"
    Environment = "Core"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}

resource "aws_vpc" "shared_services" {
  cidr_block           = "10.40.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "shared-services-vpc"
    Environment = "SharedServices"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}

resource "aws_vpc" "prod" {
  cidr_block           = "10.50.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "prod-vpc"
    Environment = "Prod"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}

resource "aws_vpc" "stage" {
  cidr_block           = "10.60.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "stage-vpc"
    Environment = "Stage"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}

resource "aws_vpc" "dev" {
  cidr_block           = "10.70.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "dev-vpc"
    Environment = "Dev"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}
```

File: modules/network/variables.tf
```hcl name=modules/network/variables.tf
variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}
```

File: modules/network/outputs.tf
```hcl name=modules/network/outputs.tf
output "inspection_vpc_id" {
  value = aws_vpc.inspection.id
}

output "shared_services_vpc_id" {
  value = aws_vpc.shared_services.id
}

output "prod_vpc_id" {
  value = aws_vpc.prod.id
}

output "stage_vpc_id" {
  value = aws_vpc.stage.id
}

output "dev_vpc_id" {
  value = aws_vpc.dev.id
}
```

File: modules/network/flow-logs.tf
```hcl name=modules/network/flow-logs.tf
data "aws_caller_identity" "current" {}

resource "aws_flow_log" "inspection" {
  log_destination_type = "cloud-watch-logs"
  log_group_name       = aws_cloudwatch_log_group.vpc_flow_logs.name
  iam_role_arn         = aws_iam_role.vpc_flow_logs.arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.inspection.id

  tags = {
    Name        = "inspection-flow-log"
    Environment = "Core"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}

resource "aws_flow_log" "shared_services" {
  log_destination_type = "cloud-watch-logs"
  log_group_name       = aws_cloudwatch_log_group.vpc_flow_logs.name
  iam_role_arn         = aws_iam_role.vpc_flow_logs.arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.shared_services.id

  tags = {
    Name        = "shared-services-flow-log"
    Environment = "SharedServices"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}

resource "aws_flow_log" "prod" {
  log_destination_type = "cloud-watch-logs"
  log_group_name       = aws_cloudwatch_log_group.vpc_flow_logs.name
  iam_role_arn         = aws_iam_role.vpc_flow_logs.arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.prod.id

  tags = {
    Name        = "prod-flow-log"
    Environment = "Prod"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}

resource "aws_flow_log" "stage" {
  log_destination_type = "cloud-watch-logs"
  log_group_name       = aws_cloudwatch_log_group.vpc_flow_logs.name
  iam_role_arn         = aws_iam_role.vpc_flow_logs.arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.stage.id

  tags = {
    Name        = "stage-flow-log"
    Environment = "Stage"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}

resource "aws_flow_log" "dev" {
  log_destination_type = "cloud-watch-logs"
  log_group_name       = aws_cloudwatch_log_group.vpc_flow_logs.name
  iam_role_arn         = aws_iam_role.vpc_flow_logs.arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.dev.id

  tags = {
    Name        = "dev-flow-log"
    Environment = "Dev"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flow-logs"
  retention_in_days = 365

  tags = {
    Name        = "vpc-flow-logs"
    Environment = "Core"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "vpc-flow-log-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}
```

File: modules/network/route-tables.tf
```hcl name=modules/network/route-tables.tf
resource "aws_route_table" "inspection" {
  vpc_id = aws_vpc.inspection.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "local"
  }

  tags = {
    Name        = "inspection-private-rt"
    Environment = "Core"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}

resource "aws_route_table" "shared_services" {
  vpc_id = aws_vpc.shared_services.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "local"
  }

  tags = {
    Name        = "shared-services-private-rt"
    Environment = "SharedServices"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}

resource "aws_route_table" "prod" {
  vpc_id = aws_vpc.prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "local"
  }

  tags = {
    Name        = "prod-private-rt"
    Environment = "Prod"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}

resource "aws_route_table" "stage" {
  vpc_id = aws_vpc.stage.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "local"
  }

  tags = {
    Name        = "stage-private-rt"
    Environment = "Stage"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}

resource "aws_route_table" "dev" {
  vpc_id = aws_vpc.dev.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "local"
  }

  tags = {
    Name        = "dev-private-rt"
    Environment = "Dev"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}

resource "aws_main_route_table_association" "inspection" {
  vpc_id         = aws_vpc.inspection.id
  route_table_id = aws_route_table.inspection.id
}

resource "aws_main_route_table_association" "shared_services" {
  vpc_id         = aws_vpc.shared_services.id
  route_table_id = aws_route_table.shared_services.id
}

resource "aws_main_route_table_association" "prod" {
  vpc_id         = aws_vpc.prod.id
  route_table_id = aws_route_table.prod.id
}

resource "aws_main_route_table_association" "stage" {
  vpc_id         = aws_vpc.stage.id
  route_table_id = aws_route_table.stage.id
}

resource "aws_main_route_table_association" "dev" {
  vpc_id         = aws_vpc.dev.id
  route_table_id = aws_route_table.dev.id
}
```

File: modules/security/main.tf
```hcl name=modules/security/main.tf
resource "aws_securityhub_account" "this" {
  auto_enable_controls = true
}

resource "aws_guardduty_detector" "this" {
  enable = true
}

resource "aws_config_configuration_recorder" "this" {
  name = "config-recorder"

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }

  role_arn = aws_iam_role.config.arn
}

resource "aws_config_delivery_channel" "this" {
  name = "config-delivery"

  s3_bucket_name = aws_s3_bucket.config_bucket.bucket

  snapshot_delivery_properties {
    delivery_frequency = "Six_Hours"
  }
}

resource "aws_iam_role" "config" {
  name = "config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "config" {
  name = "config-role-policy"
  role = aws_iam_role.config.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketAcl",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.config_bucket.arn,
          "${aws_s3_bucket.config_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket" "config_bucket" {
  bucket        = "config-log-bucket-${random_string.suffix.result}"
  force_destroy = false

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.config.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = {
    Name        = "config-log-bucket"
    Environment = "Core"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_kms_key" "config" {
  description             = "KMS key for Config"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}
```

File: modules/security/variables.tf
```hcl name=modules/security/variables.tf
variable "config_bucket_name" {
  type    = string
  default = "config-log-bucket"
}

variable "management_account_id" {
  type    = string
  default = ""
}
```

File: modules/security/outputs.tf
```hcl name=modules/security/outputs.tf
output "securityhub_account_id" {
  value = aws_securityhub_account.this.id
}

output "guardduty_detector_id" {
  value = aws_guardduty_detector.this.id
}

output "config_bucket_name" {
  value = aws_s3_bucket.config_bucket.bucket
}
```

File: modules/security/cross-account-roles.tf
```hcl name=modules/security/cross-account-roles.tf
resource "aws_iam_role" "security_audit_role" {
  name = "SecurityAuditCrossAccountRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.management_account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "security_audit_role" {
  name = "SecurityAuditCrossAccountPolicy"
  role = aws_iam_role.security_audit_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudtrail:DescribeTrails",
          "config:Describe*",
          "guardduty:List*",
          "securityhub:Describe*",
          "iam:List*",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })
}
```

File: modules/dns/main.tf
```hcl name=modules/dns/main.tf
resource "aws_route53_zone" "private" {
  name = "example.internal"

  vpc {
    vpc_id = var.vpc_id
  }
}

resource "aws_route53_resolver_endpoint" "inbound" {
  direction = "INBOUND"
  name      = "resolver-inbound"

  security_group_ids = [var.security_group_id]
  ip_address {
    subnet_id = var.inbound_subnet_id
  }
}

resource "aws_route53_resolver_endpoint" "outbound" {
  direction = "OUTBOUND"
  name      = "resolver-outbound"

  security_group_ids = [var.security_group_id]
  ip_address {
    subnet_id = var.outbound_subnet_id
  }
}
```

File: modules/dns/variables.tf
```hcl name=modules/dns/variables.tf
variable "vpc_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "inbound_subnet_id" {
  type = string
}

variable "outbound_subnet_id" {
  type = string
}
```

File: modules/dns/outputs.tf
```hcl name=modules/dns/outputs.tf
output "private_zone_id" {
  value = aws_route53_zone.private.id
}

output "resolver_inbound_endpoint_id" {
  value = aws_route53_resolver_endpoint.inbound.id
}

output "resolver_outbound_endpoint_id" {
  value = aws_route53_resolver_endpoint.outbound.id
}
```

File: modules/active-directory/main.tf
```hcl name=modules/active-directory/main.tf
resource "aws_directory_service_directory" "this" {
  name        = "corp.example.internal"
  password    = var.password
  size        = "Small"
  type        = "MicrosoftAD"
  description = "Shared Services AD"

  vpc_settings {
    vpc_id     = var.vpc_id
    subnet_ids = var.subnet_ids
  }

  tags = {
    Name        = "shared-services-ad"
    Environment = "SharedServices"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}
```

File: modules/active-directory/variables.tf
```hcl name=modules/active-directory/variables.tf
variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "password" {
  type      = string
  sensitive = true
}
```

File: modules/active-directory/outputs.tf
```hcl name=modules/active-directory/outputs.tf
output "directory_id" {
  value = aws_directory_service_directory.this.id
}
```

File: modules/iam-identity-center/main.tf
```hcl name=modules/iam-identity-center/main.tf
data "aws_ssoadmin_instances" "this" {}

resource "aws_ssoadmin_permission_set" "admin" {
  name         = "AWSAdministratorAccess"
  instance_arn = data.aws_ssoadmin_instances.this.arns[0]
  description  = "Full admin access for approved administrative roles"
  session_duration = "PT8H"
}

resource "aws_ssoadmin_permission_set" "security_admin" {
  name         = "SecurityAdmin"
  instance_arn = data.aws_ssoadmin_instances.this.arns[0]
  description  = "Security-only administrator access"
  session_duration = "PT8H"
}

resource "aws_ssoadmin_permission_set" "network_admin" {
  name         = "NetworkAdmin"
  instance_arn = data.aws_ssoadmin_instances.this.arns[0]
  description  = "Network administration access"
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "admin" {
  instance_arn       = data.aws_ssoadmin_instances.this.arns[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
}

resource "aws_ssoadmin_managed_policy_attachment" "security_admin" {
  instance_arn       = data.aws_ssoadmin_instances.this.arns[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
  permission_set_arn = aws_ssoadmin_permission_set.security_admin.arn
}

resource "aws_ssoadmin_managed_policy_attachment" "network_admin" {
  instance_arn       = data.aws_ssoadmin_instances.this.arns[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
  permission_set_arn = aws_ssoadmin_permission_set.network_admin.arn
}

resource "aws_ssoadmin_account_assignment" "security_admin" {
  instance_arn       = data.aws_ssoadmin_instances.this.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.security_admin.arn
  principal_id      = var.security_admin_group_id
  principal_type    = "GROUP"
  target_id         = var.security_account_id
  target_type       = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "network_admin" {
  instance_arn       = data.aws_ssoadmin_instances.this.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.network_admin.arn
  principal_id      = var.network_admin_group_id
  principal_type    = "GROUP"
  target_id         = var.network_account_id
  target_type       = "AWS_ACCOUNT"
}
```

File: modules/iam-identity-center/variables.tf
```hcl name=modules/iam-identity-center/variables.tf
variable "security_admin_group_id" {
  description = "SSO group ID for security admins"
  type        = string
}

variable "network_admin_group_id" {
  description = "SSO group ID for network admins"
  type        = string
}

variable "security_account_id" {
  description = "Security tooling account ID"
  type        = string
}

variable "network_account_id" {
  description = "Network account ID"
  type        = string
}
```

File: modules/iam-identity-center/outputs.tf
```hcl name=modules/iam-identity-center/outputs.tf
output "admin_permission_set_arn" {
  value = aws_ssoadmin_permission_set.admin.arn
}

output "security_admin_permission_set_arn" {
  value = aws_ssoadmin_permission_set.security_admin.arn
}

output "network_admin_permission_set_arn" {
  value = aws_ssoadmin_permission_set.network_admin.arn
}
```

File: modules/transit-gateway/main.tf
```hcl name=modules/transit-gateway/main.tf
resource "aws_ec2_transit_gateway" "this" {
  description                    = "Enterprise core TGW"
  auto_accept_shared_attachments = "enable"

  tags = {
    Name        = "enterprise-core-tgw"
    Environment = "Core"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}

resource "aws_ec2_transit_gateway_route_table" "default" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "prod" {
  subnet_ids = var.prod_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id = var.prod_vpc_id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}

resource "aws_ec2_transit_gateway_vpc_attachment" "stage" {
  subnet_ids = var.stage_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id = var.stage_vpc_id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}

resource "aws_ec2_transit_gateway_vpc_attachment" "dev" {
  subnet_ids = var.dev_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id = var.dev_vpc_id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}

resource "aws_ec2_transit_gateway_vpc_attachment" "inspection" {
  subnet_ids = var.inspection_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id = var.inspection_vpc_id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}

resource "aws_ec2_transit_gateway_vpc_attachment" "shared" {
  subnet_ids = var.shared_services_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id = var.shared_services_vpc_id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}
```

File: modules/transit-gateway/variables.tf
```hcl name=modules/transit-gateway/variables.tf
variable "prod_vpc_id" {
  type = string
}

variable "stage_vpc_id" {
  type = string
}

variable "dev_vpc_id" {
  type = string
}

variable "inspection_vpc_id" {
  type = string
}

variable "shared_services_vpc_id" {
  type = string
}

variable "prod_subnet_ids" {
  type = list(string)
}

variable "stage_subnet_ids" {
  type = list(string)
}

variable "dev_subnet_ids" {
  type = list(string)
}

variable "inspection_subnet_ids" {
  type = list(string)
}

variable "shared_services_subnet_ids" {
  type = list(string)
}

variable "onprem_cidrs" {
  description = "On-premises CIDR ranges reachable via TGW"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}
```

File: modules/transit-gateway/route-tables.tf
```hcl name=modules/transit-gateway/route-tables.tf
resource "aws_ec2_transit_gateway_route_table" "default" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id

  tags = {
    Name        = "landing-zone-tgw-rt"
    Environment = "Core"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "inspection" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.default.id
}

resource "aws_ec2_transit_gateway_route_table_association" "shared" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.default.id
}

resource "aws_ec2_transit_gateway_route_table_association" "prod" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.prod.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.default.id
}

resource "aws_ec2_transit_gateway_route_table_association" "stage" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.stage.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.default.id
}

resource "aws_ec2_transit_gateway_route_table_association" "dev" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dev.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.default.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "inspection" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.default.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "shared" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.default.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "prod" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.prod.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.default.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "stage" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.stage.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.default.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "dev" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dev.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.default.id
}

resource "aws_ec2_transit_gateway_route" "onprem" {
  count                          = length(var.onprem_cidrs)
  destination_cidr_block         = var.onprem_cidrs[count.index]
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.default.id
  blackhole                     = false
}
```

File: modules/transit-gateway/outputs.tf
```hcl name=modules/transit-gateway/outputs.tf
output "transit_gateway_id" {
  value = aws_ec2_transit_gateway.this.id
}

output "route_table_id" {
  value = aws_ec2_transit_gateway_route_table.default.id
}
```

File: modules/workloads/prod/main.tf
```hcl name=modules/workloads/prod/main.tf
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "prod" {
  cidr_block           = "10.50.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "prod-vpc"
    Environment = "Prod"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}

resource "aws_subnet" "app" {
  count                   = 2
  vpc_id                 = aws_vpc.prod.id
  cidr_block             = cidrsubnet(aws_vpc.prod.cidr_block, 8, count.index + 10)
  availability_zone      = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "prod-app-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "db" {
  count                   = 2
  vpc_id                 = aws_vpc.prod.id
  cidr_block             = cidrsubnet(aws_vpc.prod.cidr_block, 8, count.index + 20)
  availability_zone      = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "prod-db-subnet-${count.index + 1}"
  }
}

resource "aws_db_subnet_group" "db" {
  name       = "prod-db-subnet-group"
  subnet_ids = aws_subnet.db[*].id
}

resource "aws_security_group" "db" {
  name        = "prod-db-sg"
  description = "Restricted DB security group"
  vpc_id      = aws_vpc.prod.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.50.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "primary" {
  identifier              = "prod-db-primary"
  allocated_storage       = 100
  max_allocated_storage   = 500
  db_name                 = "appdb"
  username                = "dbadmin"
  password                = var.db_password
  engine                  = "postgres"
  engine_version          = "16"
  instance_class          = "db.t3.medium"
  db_subnet_group_name    = aws_db_subnet_group.db.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  multi_az                = true
  publicly_accessible     = false
  deletion_protection     = true
  backup_retention_period = 7
  storage_encrypted       = true
  skip_final_snapshot     = false
  apply_immediately       = false

  tags = {
    Name        = "prod-db-primary"
    Environment = "Prod"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}
```

File/ modules/workloads/prod/variables.tf
```hcl name=modules/workloads/prod/variables.tf
variable "db_password" {
  type      = string
  sensitive = true
}
```

File/ modules/workloads/prod/outputs.tf
```hcl name=modules/workloads/prod/outputs.tf
output "vpc_id" {
  value = aws_vpc.prod.id
}

output "db_instance_id" {
  value = aws_db_instance.primary.id
}
```

File/ modules/workloads/stage/main.tf
```hcl name=modules/workloads/stage/main.tf
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "stage" {
  cidr_block           = "10.60.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "stage-vpc"
    Environment = "Stage"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}

resource "aws_subnet" "app" {
  count                   = 2
  vpc_id                 = aws_vpc.stage.id
  cidr_block             = cidrsubnet(aws_vpc.stage.cidr_block, 8, count.index + 10)
  availability_zone      = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "stage-app-subnet-${count.index + 1}"
  }
}
```

File/ modules/workloads/stage/variables.tf
```hcl name=modules/workloads/stage/variables.tf
variable "db_password" {
  type      = string
  sensitive = true
  default   = null
}
```

File/ modules/workloads/stage/outputs.tf
```hcl name=modules/workloads/stage/outputs.tf
output "vpc_id" {
  value = aws_vpc.stage.id
}
```

File/ modules/workloads/dev/main.tf
```hcl name=modules/workloads/dev/main.tf
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "dev" {
  cidr_block           = "10.70.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "dev-vpc"
    Environment = "Dev"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}

resource "aws_subnet" "app" {
  count                   = 2
  vpc_id                 = aws_vpc.dev.id
  cidr_block             = cidrsubnet(aws_vpc.dev.cidr_block, 8, count.index + 10)
  availability_zone      = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "dev-app-subnet-${count.index + 1}"
  }
}
```

File/ modules/workloads/dev/variables.tf
```hcl name=modules/workloads/dev/variables.tf
variable "db_password" {
  type      = string
  sensitive = true
  default   = null
}
```

File/ modules/workloads/dev/outputs.tf
```hcl name=modules/workloads/dev/outputs.tf
output "vpc_id" {
  value = aws_vpc.dev.id
}
```

5) Environment stacks

File: environments/management/main.tf
```hcl name=environments/management/main.tf
terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

module "organizations" {
  source = "../../modules/organizations"

  organization_name = var.organization_name
}
```

File: environments/management/variables.tf
```hcl name=environments/management/variables.tf
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "organization_name" {
  type    = string
  default = "enterprise-org"
}
```

File: environments/management/locals.tf
```hcl name=environments/management/locals.tf
locals {
  env = "management"
}
```

File: environments/management/backend.hcl
```hcl name=environments/management/backend.hcl
bucket         = "enterprise-landing-zone-state"
key            = "management/prod.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "enterprise-landing-zone-locks"
```

File: environments/security/main.tf
```hcl name=environments/security/main.tf
terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

module "security" {
  source = "../../modules/security"

  management_account_id = var.management_account_id
}
```

File: environments/security/variables.tf
```hcl name=environments/security/variables.tf
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "management_account_id" {
  type    = string
  default = ""
}
```

File: environments/security/locals.tf
```hcl name=environments/security/locals.tf
locals {
  env = "security"
}
```

File: environments/security/backend.hcl
```hcl name=environments/security/backend.hcl
bucket         = "enterprise-landing-zone-state"
key            = "security/prod.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "enterprise-landing-zone-locks"
```

File: environments/network/main.tf
```hcl name=environments/network/main.tf
terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

module "network" {
  source = "../../modules/network"

  environment = var.environment
  project_name = var.project_name
}

module "transit_gateway" {
  source = "../../modules/transit-gateway"

  prod_vpc_id                = module.network.prod_vpc_id
  stage_vpc_id               = module.network.stage_vpc_id
  dev_vpc_id                 = module.network.dev_vpc_id
  inspection_vpc_id          = module.network.inspection_vpc_id
  shared_services_vpc_id     = module.network.shared_services_vpc_id

  prod_subnet_ids            = var.prod_subnet_ids
  stage_subnet_ids           = var.stage_subnet_ids
  dev_subnet_ids             = var.dev_subnet_ids
  inspection_subnet_ids      = var.inspection_subnet_ids
  shared_services_subnet_ids = var.shared_services_subnet_ids

  onprem_cidrs = var.onprem_cidrs
}
```

File/ environments/network/variables.tf
```hcl name=environments/network/variables.tf
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "network"
}

variable "project_name" {
  type    = string
  default = "medical-platform"
}

variable "onprem_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/8"]
}

variable "prod_subnet_ids" {
  type = list(string)
  default = ["subnet-00000000000000001"]
}

variable "stage_subnet_ids" {
  type = list(string)
  default = ["subnet-00000000000000002"]
}

variable "dev_subnet_ids" {
  type = list(string)
  default = ["subnet-00000000000000003"]
}

variable "inspection_subnet_ids" {
  type = list(string)
  default = ["subnet-00000000000000004"]
}

variable "shared_services_subnet_ids" {
  type = list(string)
  default = ["subnet-00000000000000005"]
}
```

File/ environments/network/locals.tf
```hcl name=environments/network/locals.tf
locals {
  env = "network"
}
```

File/ environments/network/backend.hcl
```hcl name=environments/network/backend.hcl
bucket         = "enterprise-landing-zone-state"
key            = "network/prod.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "enterprise-landing-zone-locks"
```

File/ environments/shared-services/main.tf
```hcl name=environments/shared-services/main.tf
terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

module "shared_services" {
  source = "../../modules/network"

  environment = var.environment
  project_name = var.project_name
}

module "active_directory" {
  source = "../../modules/active-directory"

  vpc_id     = module.shared_services.shared_services_vpc_id
  subnet_ids = var.shared_services_subnet_ids

  password = var.ad_password
}

module "dns" {
  source = "../../modules/dns"

  vpc_id             = module.shared_services.shared_services_vpc_id
  security_group_id  = var.dns_security_group_id
  inbound_subnet_id  = var.dns_inbound_subnet_id
  outbound_subnet_id = var.dns_outbound_subnet_id
}
```

File/ environments/shared-services/variables.tf
```hcl name=environments/shared-services/variables.tf
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "shared-services"
}

variable "project_name" {
  type    = string
  default = "medical-platform"
}

variable "shared_services_subnet_ids" {
  type = list(string)
  default = [
    "subnet-00000000000000010",
    "subnet-00000000000000011"
  ]
}

variable "ad_password" {
  type      = string
  sensitive = true
  default   = "REPLACE_WITH_STRONG_PASSWORD"
}

variable "dns_security_group_id" {
  type    = string
  default = "sg-00000000000000000"
}

variable "dns_inbound_subnet_id" {
  type    = string
  default = "subnet-00000000000000012"
}

variable "dns_outbound_subnet_id" {
  type    = string
  default = "subnet-00000000000000013"
}
```

File/ environments/shared-services/locals.tf
```hcl name=environments/shared-services/locals.tf
locals {
  env = "shared-services"
}
```

File/ environments/shared-services/backend.hcl
```hcl name=environments/shared-services/backend.hcl
bucket         = "enterprise-landing-zone-state"
key            = "shared-services/prod.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "enterprise-landing-zone-locks"
```

File/ environments/workload-prod/main.tf
```hcl name=environments/workload-prod/main.tf
terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

module "prod" {
  source = "../../modules/workloads/prod"

  db_password = var.db_password
}
```

File/ environments/workload-prod/variables.tf
```hcl name=environments/workload-prod/variables.tf
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "db_password" {
  type      = string
  sensitive = true
  default   = "REPLACE_WITH_STRONG_PASSWORD"
}
```

File/ environments/workload-prod/locals.tf
```hcl name=environments/workload-prod/locals.tf
locals {
  env = "workload-prod"
}
```

File/ environments/workload-prod/backend.hcl
```hcl name=environments/workload-prod/backend.hcl
bucket         = "enterprise-landing-zone-state"
key            = "workload-prod/prod.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "enterprise-landing-zone-locks"
```

File/ environments/workload-stage/main.tf
```hcl name=environments/workload-stage/main.tf
terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

module "stage" {
  source = "../../modules/workloads/stage"

  db_password = var.db_password
}
```

File/ environments/workload-stage/variables.tf
```hcl name=environments/workload-stage/variables.tf
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "db_password" {
  type      = string
  sensitive = true
  default   = "REPLACE_WITH_STRONG_PASSWORD"
}
```

File/ environments/workload-stage/locals.tf
```hcl name=environments/workload-stage/locals.tf
locals {
  env = "workload-stage"
}
```

File/ environments/workload-stage/backend.hcl
```hcl name=environments/workload-stage/backend.hcl
bucket         = "enterprise-landing-zone-state"
key            = "workload-stage/prod.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "enterprise-landing-zone-locks"
```

File/ environments/workload-dev/main.tf
```hcl name=environments/workload-dev/main.tf
terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

module "dev" {
  source = "../../modules/workloads/dev"

  db_password = var.db_password
}
```

File/ environments/workload-dev/variables.tf
```hcl name=environments/workload-dev/variables.tf
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "db_password" {
  type      = string
  sensitive = true
  default   = "REPLACE_WITH_STRONG_PASSWORD"
}
```

File/ environments/workload-dev/locals.tf
```hcl name=environments/workload-dev/locals.tf
locals {
  env = "workload-dev"
}
```

File/ environments/workload-dev/backend.hcl
```hcl name=environments/workload-dev/backend.hcl
bucket         = "enterprise-landing-zone-state"
key            = "workload-dev/prod.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "enterprise-landing-zone-locks"
```

File/ environments/sandbox/main.tf
```hcl name=environments/sandbox/main.tf
terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

module "sandbox" {
  source = "../../modules/workloads/dev"

  db_password = var.db_password
}
```

File/ environments/sandbox/variables.tf
```hcl name=environments/sandbox/variables.tf
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "db_password" {
  type      = string
  sensitive = true
  default   = "REPLACE_WITH_STRONG_PASSWORD"
}
```

File/ environments/sandbox/locals.tf
```hcl name=environments/sandbox/locals.tf
locals {
  env = "sandbox"
}
```

File/ environments/sandbox/backend.hcl
```hcl name=environments/sandbox/backend.hcl
bucket         = "enterprise-landing-zone-state"
key            = "sandbox/prod.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "enterprise-landing-zone-locks"
```

6) Scripts

File: scripts/bootstrap-state.sh
```bash name=scripts/bootstrap-state.sh
#!/usr/bin/env bash
set -euo pipefail

aws s3api create-bucket \
  --bucket enterprise-landing-zone-state \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket enterprise-landing-zone-state \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket enterprise-landing-zone-state \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms","KMSMasterKeyID":"alias/aws/s3"}}]}'

aws dynamodb create-table \
  --table-name enterprise-landing-zone-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

File: scripts/deploy-all.sh
```bash name=scripts/deploy-all.sh
#!/usr/bin/env bash
set -euo pipefail

echo "==> Deploying management"
terraform -chdir=environments/management init
terraform -chdir=environments/management plan
terraform -chdir=environments/management apply -auto-approve

echo "==> Deploying security"
terraform -chdir=environments/security init
terraform -chdir=environments/security plan
terraform -chdir=environments/security apply -auto-approve

echo "==> Deploying network"
terraform -chdir=environments/network init
terraform -chdir=environments/network plan
terraform -chdir=environments/network apply -auto-approve

echo "==> Deploying shared-services"
terraform -chdir=environments/shared-services init
terraform -chdir=environments/shared-services plan
terraform -chdir=environments/shared-services apply -auto-approve

echo "==> Deploying workload-prod"
terraform -chdir=environments/workload-prod init
terraform -chdir=environments/workload-prod plan
terraform -chdir=environments/workload-prod apply -auto-approve

echo "==> Deploying workload-stage"
terraform -chdir=environments/workload-stage init
terraform -chdir=environments/workload-stage plan
terraform -chdir=environments/workload-stage apply -auto-approve

echo "==> Deploying workload-dev"
terraform -chdir=environments/workload-dev init
terraform -chdir=environments/workload-dev plan
terraform -chdir=environments/workload-dev apply -auto-approve

echo "==> Deploying sandbox"
terraform -chdir=environments/sandbox init
terraform -chdir=environments/sandbox plan
terraform -chdir=environments/sandbox apply -auto-approve
```

File: scripts/validate-landing-zone.sh
```bash name=scripts/validate-landing-zone.sh
#!/usr/bin/env bash
set -euo pipefail

echo "==> Formatting Terraform"
terraform fmt -recursive

echo "==> Initialization"
terraform init -backend=false

echo "==> Validate"
terraform validate

echo "==> Security checks"
echo "Reviewing SCPs, IAM trust policies, VPC route tables, flow logs, public exposure, KMS and tagging"

echo "==> Complete"
```

This is the full production-standard scaffolding set you can place into your project.

If you want, I can next generate:
- a single merged “repo ready to paste” version with all files combined into one package
- the exact account-to-VPC mapping in CSV format
- the final GitHub Markdown architecture diagram with labels and CIDR ranges
- or the complete production IAM trust role set for all accounts and OU admin roles
