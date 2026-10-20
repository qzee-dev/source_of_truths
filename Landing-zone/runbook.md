Below is the full blueprint, organized for implementation, with a modular Terraform layout and a state-file strategy that reduces blast radius.

Important note:
- This is an enterprise landing-zone blueprint for a regulated HIPAA-aligned environment.
- It is architecture guidance and should be validated with your security, compliance, and networking teams before production deployment.
- The prompt mentions 7 accounts, then also lists a shared-system account; I am treating shared-system as a dedicated deployment/control-plane account, which is the cleaner production design. If you need exactly seven accounts, merge Network and Shared-System into the Infrastructure account.

1) Architecture overview

The design is a centralized AWS Organization model with:
- management account
- log archive account
- security tooling account
- network account
- production workloads account
- staging workloads account
- development workloads account
- shared-system automation account

The pattern is:
- management account: org, billing, root guardrails
- security OU: log archive, security tooling
- infrastructure OU: network, shared-system, hybrid core
- workloads-prod OU: production workloads
- workloads-nonprod OU: staging + development
- sandbox OU: isolated experiments

This arrangement gives:
- least-privilege separation
- centralized logging and security controls
- isolated production access
- blast-radius control
- HIPAA-aligned boundary design

2) Organizational structure and account model

Recommended OU model:
- Security-OU
  - Log Archive Account
  - Security Tooling Account
- Infrastructure-OU
  - Network Account
  - Shared-System Account
- Workloads-Prod-OU
  - Production Account
- Workloads-NonProd-OU
  - Staging Account
  - Development Account
- Sandbox-OU
  - Sandbox Account

This is the preferred design for production because it keeps shared deployment automation separate from app workloads.

3) Recommended AWS account list

- Management Account
  - root org administration
  - billing
  - IAM root lock
  - policy enforcement
- Log Archive Account
  - CloudTrail, CloudWatch logs, Config logs, S3 access logs
- Security Tooling Account
  - GuardDuty, Security Hub, IAM Access Analyzer, Amazon Macie, Inspector
- Network Account
  - transit gateway
  - inspection VPC
  - shared services VPC
  - central routing
- Production Account
  - production workloads
  - production database
  - workload EKS/ECS/EC2
- Staging Account
  - mirrored production testing
- Development Account
  - developer workloads
- Shared-System Account
  - centralized automation, CI/CD, pipeline deployer
  - only account allowed to deploy across accounts using cross-account roles
  - no direct app workloads

4) Baseline organizational controls

Use AWS Organizations with:
- SCP baseline
- OUs with scoped policies
- centralized logging and config
- IAM Identity Center for human access

5) Baseline SCP requirements

The baseline SCP should enforce:
- MFA for administrative actions
- restrict AWS regions to approved HIPAA-eligible regions
- deny modification of CloudTrail and Config recorder
- deny deletion or modification of immutable logs and access logs
- block public S3 bucket creation where not explicitly allowed
- restrict root user actions across member accounts
- restrict high-risk actions to approved roles only

Sample SCP (conceptual snippet):
```hcl name=scp-baseline.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "RestrictRootUsage",
      "Effect": "Deny",
      "Action": [
        "iam:CreateLoginProfile",
        "iam:DeleteAccountAlias",
        "iam:UpdateAccountPasswordPolicy",
        "iam:CreateAccessKey"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:PrincipalArn": "arn:aws:iam::*:root"
        }
      }
    },
    {
      "Sid": "RequireMfaForAdmins",
      "Effect": "Deny",
      "Action": [
        "iam:CreateUser",
        "iam:CreateAccessKey",
        "iam:AttachUserPolicy",
        "iam:PutUserPolicy",
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
    }
  ]
}
```

6) OU-specific SCPs

Workloads-Prod-OU SCP:
- requires CMK-backed encryption for S3/EBS
- denies public S3 bucket creation
- denies detaching VPC Flow Logs
- restricts to HIPAA-eligible AWS services
- denies insecure network creation
- prohibits encryption disablement

Workloads-NonProd-OU SCP:
- deny oversized EC2/RDS instances
- deny unencrypted storage
- deny IGW creation in nonprod unless explicitly granted
- restrict cross-environment route propagation

Sandbox-OU SCP:
- deny high-cost services
- deny network peering
- deny hybrid connections
- deny direct VPC attachment to production

Sample SCP (conceptual):
```hcl name=scp-prod.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyPublicS3Buckets",
      "Effect": "Deny",
      "Action": [
        "s3:CreateBucket"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "s3:PublicAccessBlock": "true"
        }
      }
    },
    {
      "Sid": "RequireCMKForEncryptedStorage",
      "Effect": "Deny",
      "Action": [
        "ec2:CreateVolume",
        "s3:PutBucketEncryption"
      ],
      "Resource": "*",
      "Condition": {
        "Null": {
          "kms:GrantId": "true"
        }
      }
    }
  ]
}
```

7) IAM Identity Center and least-privilege access model

Enable IAM Identity Center centrally from the Management account and delegate administration to Security Tooling account.

Groups:
- SecOps-Admin-Group
  - Permission Set: SecurityAdminAccess
  - Accounts: Log Archive, Security Tooling
- NetOps-Admin-Group
  - Permission Set: NetworkAdminAccess
  - Accounts: Network
- FinOps-Analyst-Group
  - Permission Set: BillingViewAccess
  - Accounts: Management
- DevOps-Prod-Group
  - Permission Set: ReadOnlyAccess
  - Permission Set: BreakGlassAdmin
  - Accounts: Production
- Engineering-NonProd-Group
  - Permission Set: PowerUserAccess
  - Accounts: Development, Staging

Permission set concept:
```hcl name=identity-center-permission-set.tf
resource "aws_ssoadmin_permission_set" "security_admin" {
  name         = "SecurityAdminAccess"
  instance_arn = aws_ssoadmin_instance.this.arn
  description  = "Security admin access for security tools and logs"
}

resource "aws_ssoadmin_managed_policy_attachment" "security_admin" {
  managed_policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
  permission_set_arn = aws_ssoadmin_permission_set.security_admin.arn
}
```

8) Cost governance

Tag standard:
- Environment: Prod, Stage, Dev, Core
- ProjectID
- Owner
- CostCenter
- Compliance: HIPAA
- Automation: Terraform

Recommended tagging strategy:
```hcl name=tags.tf
locals {
  common_tags = {
    Environment = "Prod"
    ProjectID   = "medical-platform"
    Owner       = "platform-team"
    CostCenter  = "CC-1001"
    Compliance  = "HIPAA"
    Automation  = "Terraform"
  }
}
```

Cost controls:
- AWS Budgets at 80% and 100% thresholds
- Amazon SNS topic with email/SMS
- Cost Explorer enabled
- CUR 2.0 delivered to S3 bucket in Log Archive account

9) Network architecture

Hub-and-spoke model:
- Inspection VPC (hub)
- Shared Services VPC (hub)
- Spokes:
  - Production VPC
  - Staging VPC
  - Development VPC

Inspection VPC:
- internet gateway sits here
- NAT gateways sit here
- AWS Network Firewall inside inspection subnets
- all east-west and north-south traffic flows through firewall
- route tables force all traffic to firewall appliances

10) Inspection VPC design

Suggested VPC:
- VPC CIDR: 10.30.0.0/16
- Subnets:
  - public-ingress: 10.30.10.0/24
  - public-egress: 10.30.11.0/24
  - firewall-a: 10.30.20.0/24
  - firewall-b: 10.30.21.0/24
- IGW in inspection VPC
- NAT gateways in inspection VPC
- AWS Network Firewall endpoints in isolated subnets

11) Shared services VPC design

Shared Services VPC:
- VPC CIDR: 10.40.0.0/16
- Subnets:
  - management: 10.40.10.0/24
  - dns: 10.40.20.0/24
  - ad: 10.40.30.0/24
- Route 53 private hosted zones
- inbound/outbound resolvers
- AD integration
- DNS for workloads

12) Production spoke VPC design

Suggested VPC:
- VPC CIDR: 10.50.0.0/16
- Private app subnets:
  - 10.50.10.0/24
  - 10.50.11.0/24
- Private DB subnets:
  - 10.50.20.0/24
  - 10.50.21.0/24
- Private app layer
- RDS DB in DB subnets
- EKS/ECS or EC2 app in app subnets

13) Hybrid connectivity and Active Directory model

Recommended hybrid pattern:
- AWS Managed Microsoft AD in Shared Services VPC
- on-prem AD with two-way forest trust
- AWS Direct Connect primary
- active-active Site-to-Site VPN over DX
- no single point of failure

This gives:
- resilient authentication
- cloud workloads keep local AD latency low
- if the connection is cut, cloud AD still works for local auth

14) Hybrid connectivity architecture

Use:
- AWS Direct Connect
- two copper/fiber links if possible
- Site-to-Site VPN as active-active backup
- production route tables only allow on-prem database CIDR

Production hybrid access:
- only production VPC route to on-prem DB CIDR
- staging and dev have no route
- sandbox has no routing to hybrid
- shared services handles DNS and AD trust

Transit Gateway route tables:
- inspection-rt
- production-rt
- workload-rt
- shared-service-rt

15) Transit Gateway route table design

Production route table:
- associated to production VPC
- default route to inspection VPC
- explicit route to on-prem DB CIDR through hybrid gateway
- no route to staging or dev VPCs

Workload route table:
- associated to staging and dev VPCs
- default route to inspection VPC
- no route to on-prem DB CIDR
- no route to production VPC

Shared service route table:
- routes only DNS/AD traffic to workloads
- blocks cross-environment contamination

Inspection route table:
- sees all spoke routes and on-prem hybrid attachments
- forces routing through firewall inspection

16) DNS architecture

Shared Services VPC runs:
- Amazon Route 53 private hosted zones
- inbound resolver for internal workloads
- outbound resolver for split-horizon DNS
- DNS forwarding to on-prem if needed

This gives:
- internal workload DNS
- centralized name resolution
- secure hybrid DNS design

17) HIPAA security controls

The design includes:
- no public DB
- no public app tiers
- encryption at rest and in transit
- KMS customer-managed keys
- CloudTrail and Config
- VPC Flow Logs
- GuardDuty, Security Hub, Inspector, Macie
- AWS WAF and Network Firewall
- private endpoints or TGW routing where possible
- least-privilege IAM
- centralized audit logs in Log Archive account

18) Terraform repo layout with multilayer state

Use this structure:

```text name=repo-layout.txt
terraform-aws-landing-zone/
├── README.md
├── versions.tf
├── providers.tf
├── locals.tf
├── variables.tf
├── modules/
│   ├── organizations/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── network/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── dns/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── transit-gateway/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── active-directory/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── workloads/
│       ├── prod/
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── stage/
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── dev/
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
├── environments/
│   ├── management/
│   │   ├── backend.hcl
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── locals.tf
│   ├── security/
│   │   ├── backend.hcl
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── locals.tf
│   ├── network/
│   │   ├── backend.hcl
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── locals.tf
│   ├── shared-services/
│   │   ├── backend.hcl
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── locals.tf
│   ├── workload-prod/
│   │   ├── backend.hcl
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── locals.tf
│   ├── workload-stage/
│   │   ├── backend.hcl
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── locals.tf
│   ├── workload-dev/
│   │   ├── backend.hcl
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── locals.tf
│   └── sandbox/
│       ├── backend.hcl
│       ├── main.tf
│       ├── variables.tf
│       └── locals.tf
├── scripts/
│   ├── validate-landing-zone.sh
│   ├── deploy-security.sh
│   └── bootstrap-org.sh
└── .gitignore
```

This is a production-grade layout.

19) State file strategy with reduced blast radius

State file separation:
- org state
- security state
- logging state
- network state
- shared-services state
- workload-prod state
- workload-stage state
- workload-dev state
- sandbox state

This keeps blast radius low.

Example backend.hcl:
```hcl name=backend-network.hcl
bucket         = "prod-terraform-state"
key            = "network/prod.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "prod-terraform-locks"
kms_key_id     = "arn:aws:kms:us-east-1:111122223333:key/abcd-1234-efgh"
```

Example backend for prod workload:
```hcl name=backend-workload-prod.hcl
bucket         = "prod-terraform-state"
key            = "workload-prod/prod.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "prod-terraform-locks"
kms_key_id     = "arn:aws:kms:us-east-1:111122223333:key/abcd-1234-efgh"
```

Example remote-state read:
```hcl name=terraform-remote-state.tf
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "prod-terraform-state"
    key    = "network/prod.tfstate"
    region = "us-east-1"
  }
}
```

20) Example root stack for network

```hcl name=environments/network/main.tf
terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

module "network" {
  source = "../../../modules/network"

  environment = var.environment
  project_name = var.project_name
  vpc_cidrs = var.vpc_cidrs
  tags = local.common_tags
}
```

21) Example root stack for workload-prod

```hcl name=environments/workload-prod/main.tf
terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "prod-terraform-state"
    key    = "network/prod.tfstate"
    region = "us-east-1"
  }
}

module "workload_prod" {
  source = "../../../modules/workloads/prod"

  environment = var.environment
  project_name = var.project_name
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.network.outputs.app_subnet_ids
  tags = local.common_tags
}
```

22) Example module skeleton: network

```hcl name=modules/network/main.tf
resource "aws_vpc" "inspection" {
  cidr_block           = "10.30.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "inspection-vpc"
  }
}

resource "aws_vpc" "shared_services" {
  cidr_block           = "10.40.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "shared-services-vpc"
  }
}

resource "aws_vpc" "prod" {
  cidr_block           = "10.50.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "prod-vpc"
  }
}
```

23) Example module skeleton: transit gateway

```hcl name=modules/transit-gateway/main.tf
resource "aws_ec2_transit_gateway" "this" {
  description = "Enterprise core transit gateway"

  tags = {
    Name = "enterprise-tgw"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "prod" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id            = aws_vpc.prod.id
  subnet_ids        = [aws_subnet.prod_a.id, aws_subnet.prod_b.id]

  tags = {
    Name = "prod-attachment"
  }
}
```

24) Example module skeleton: security / firewall

```hcl name=modules/security/main.tf
resource "aws_network_firewall_firewall" "inspection" {
  name                = "inspection-firewall"
  firewall_policy_arn = aws_network_firewall_firewall_policy.main.arn
  subnet_mapping {
    subnet_id = aws_subnet.firewall_a.id
  }
  subnet_mapping {
    subnet_id = aws_subnet.firewall_b.id
  }
}
```

25) Example module skeleton: Route53 private hosted zone

```hcl name=modules/dns/main.tf
resource "aws_route53_zone" "private" {
  name = "example.internal"

  vpc {
    vpc_id = aws_vpc.shared_services.id
  }
}
```

26) Example module skeleton: AD

```hcl name=modules/active-directory/main.tf
resource "aws_directory_service_directory" "directory" {
  name        = "corp.example.internal"
  password    = "ReplaceMeWithSecurePassword"
  size        = "Small"
  vpc_settings {
    vpc_id     = aws_vpc.shared_services.id
    subnet_ids = [aws_subnet.ad_a.id, aws_subnet.ad_b.id]
  }
  type = "MicrosoftAD"
}
```

27) Example module skeleton: RDS workload

```hcl name=modules/workloads/prod/main.tf
resource "aws_db_instance" "primary" {
  identifier             = "prod-db"
  allocated_storage      = 100
  max_allocated_storage  = 500
  storage_type           = "gp3"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t3.medium"
  username               = "dbadmin"
  password               = var.db_password
  db_name                = "appdb"
  publicly_accessible    = false
  multi_az               = true
  backup_retention_period = 7
  storage_encrypted      = true
  deletion_protection    = true
  skip_final_snapshot    = false
}
```

28) Operational and compliance checklist

Must have:
- AWS Organizations enabled
- OUs defined and SCPs scoped
- log archive account centralized
- security tooling account centralized
- network account centralized
- KMS keys managed centrally
- IAM Identity Center deployed
- GuardDuty, Security Hub, Macie, Access Analyzer enabled
- VPC Flow Logs enabled
- CloudTrail enabled in log archive
- Config recorder enabled in log archive
- Private hosted zones enabled
- Direct Connect + VPN hybrid connectivity
- strong route isolation between prod and nonprod
- dedicated production and Sandbox boundaries
- periodic security review and controlled automation

29) Final architecture summary

This design creates a fully layered, enterprise-ready AWS landing zone that:
- aligns with AWS Well-Architected principles
- supports HIPAA-aligned workload isolation
- centralizes security and visibility
- isolates production and non-production workloads
- uses a centralized network and firewall model
- provides resilient hybrid connectivity
- reduces blast radius using multiple Terraform state files
- protects operations through SCPs, IAM Identity Center, and cost governance

This is the right blueprint to implement as a modular enterprise AWS landing zone.

If you want, I can next produce any one of the following:
- full Terraform for the entire AWS Organizations + OUs + accounts + baseline SCPs
- full Terraform for the network and transit gateway layer
- full Terraform for the hybrid connectivity + Direct Connect + VPN design
- full Terraform for the production RDS + DMS migration stack
- a repo-ready multi-state production structure with all file names and backend configs, ready to paste

I can generate the next one in the same structure and level of detail.
