# Terraform AWS Landing Zone — Phased Deployment Guide

## Overview

This repository implements a modular AWS landing zone designed for an enterprise environment with HIPAA-aligned security controls.

The architecture separates AWS accounts, security, networking, shared services, and application workloads. Terraform modules and independent state files help reduce the blast radius of infrastructure changes.

**The deployment strategy is phased:** prepare the complete Terraform codebase, deploy only the resources required for the current stage, validate costs and security, and introduce additional infrastructure as the project grows.

### Deployment Objectives

- Establish centralized AWS account governance.
- Implement secure Terraform state management.
- Enable centralized audit logging and baseline security controls.
- Separate production, staging, development, and sandbox environments.
- Deploy network and shared services only when required.
- Control recurring AWS costs.
- Maintain a clear path toward production readiness.

> **Important:** This architecture provides guidance for a HIPAA-aligned environment. It does not automatically make an AWS workload HIPAA-compliant. Validate the design with your security, compliance, networking, and operations teams before processing electronic protected health information (ePHI).

---

## 1\. Repository Structure

The repository is organized into reusable Terraform modules, environment-specific root modules, policies, bootstrap scripts, and operational scripts.

```
terraform-aws-landing-zone/
├── README.md
├── bootstrap/
│   ├── README.md
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── scripts/
│       ├── bootstrap-org.sh
│       └── bootstrap-state.sh
├── policies/
│   ├── baseline-scp.json
│   ├── prod-scp.json
│   ├── nonprod-scp.json
│   └── sandbox-scp.json
├── modules/
│   ├── organizations/
│   ├── security/
│   ├── network/
│   ├── transit-gateway/
│   ├── dns/
│   ├── active-directory/
│   └── workloads/
│       ├── prod/
│       ├── stage/
│       └── dev/
├── environments/
│   ├── management/
│   ├── security/
│   ├── network/
│   ├── shared-services/
│   ├── workload-prod/
│   ├── workload-stage/
│   ├── workload-dev/
│   └── sandbox/
├── scripts/
│   ├── validate-landing-zone.sh
│   ├── deploy-all.sh
│   └── bootstrap-state.sh
└── .gitignore
```

Each environment directory should contain its own Terraform root configuration, variables, local values, and backend configuration where applicable.

### Repository Design Principles

- Reuse modules instead of duplicating infrastructure definitions.
- Keep environment root modules independently deployable.
- Use separate Terraform state files for independently managed layers.
- Store no AWS credentials, passwords, or other secrets in source control.
- Avoid deploying every module through one unconditional root configuration.
- Keep `deploy-all.sh` out of the initial deployment workflow until its execution order, safeguards, and approval requirements have been tested.

---

## 2\. Deployment Roadmap

The full architecture can be prepared in advance, but resources should be provisioned only when required.

| Phase | Scope | Deployment approach |
| --- | --- | --- |
| Phase 0 | Repository preparation and validation | No new infrastructure |
| Phase 1 | Organizations, IAM, Terraform state, audit logging, budgets | Deploy first |
| Phase 2 | Centralized security baseline | Enable selected controls |
| Phase 3 | VPCs, routing, and Site-to-Site VPN | Deploy when needed |
| Phase 4 | DNS, Active Directory, and expanded networking | Deploy when dependencies require them |
| Phase 5 | Development and staging workloads | Deploy incrementally |
| Phase 6 | Production infrastructure and advanced security | Deploy after readiness review |
| Optional | Sandbox environment | Deploy when needed |

The monthly cost estimates below are preliminary planning allowances in USD, not fixed AWS quotes. They overlap and should not be added together without accounting for shared resources and services.

### Phase 0 — Prepare Without Deploying

**Objective:** Validate the codebase and prepare the deployment process without creating new AWS infrastructure.

Tasks:

- Review the repository structure and architecture.
- Validate Terraform syntax and formatting.
- Run infrastructure-as-code security checks.
- Define resource tags and cost budgets.
- Review AWS permissions and account requirements.
- Establish a deployment approval process.
- Document state recovery and rollback procedures.

**Expected incremental AWS infrastructure cost:** $0, excluding existing resources, paid tools, or other services already in use.

### Phase 1 — Minimum Viable Foundation

**Objective:** Establish secure account governance and Terraform operations.

Tasks:

- Configure AWS Organizations and the required organizational units.
- Create the required member accounts, either now or incrementally.
- Configure IAM Identity Center and least-privilege access.
- Bootstrap the Terraform state backend.
- Enable centralized CloudTrail audit logging.
- Apply a tested baseline SCP.
- Configure AWS Budgets and billing notifications.
- Apply consistent resource tags.

**Indicative monthly planning allowance:** $5–$40 for a lean foundation, depending on logging and optional services.

### Phase 2 — Centralized Security

**Objective:** Enable the security controls required for the landing zone.

Tasks:

- Configure AWS Config for the required resource types.
- Enable GuardDuty and selected Security Hub capabilities.
- Centralize security findings and audit records.
- Establish appropriate log retention and access restrictions.
- Configure alerts for suspicious activity and high-risk changes.
- Validate security-service coverage across the required accounts.

**Indicative incremental monthly allowance:** $20–$120, depending on usage and service configuration.

### Phase 3 — Basic Networking and VPN

**Objective:** Establish network connectivity only when required.

Tasks:

- Create the necessary VPCs and private subnets.
- Configure route tables and security groups.
- Establish Site-to-Site VPN connectivity when on-premises access is needed.
- Enable VPC Flow Logs where required.
- Validate route isolation between production and non-production environments.

**Indicative incremental monthly allowance:** $40–$150 or more, depending on the topology, connection type, and traffic.

Defer Transit Gateway and Network Firewall until the routing and inspection requirements justify them.

### Phase 4 — Shared Services

**Objective:** Deploy shared infrastructure when workloads require it.

Tasks:

- Configure private DNS and Route 53 Resolver endpoints as needed.
- Deploy AWS Managed Microsoft AD only if directory integration is required.
- Introduce Transit Gateway when multiple VPCs or accounts require centralized routing.
- Implement the necessary hybrid DNS and directory integration.
- Validate shared-service access and network boundaries.

Costs depend on the specific services deployed and how continuously they run.

### Phase 5 — Non-Production Workloads

**Objective:** Introduce development and staging environments incrementally.

Tasks:

- Deploy development workloads first.
- Add staging when production-like testing becomes necessary.
- Use appropriately sized compute and database resources.
- Schedule shutdowns for eligible non-production resources.
- Enforce storage, network, and instance-size restrictions.
- Prevent unintended connectivity to production.

### Phase 6 — Production Readiness

**Objective:** Deploy production workloads after security and operational validation.

Tasks:

- Deploy the production database and application infrastructure.
- Implement required high availability and encryption.
- Configure backup retention and recovery procedures.
- Add advanced network inspection where required.
- Validate access restrictions and audit logging.
- Complete security and compliance reviews before processing regulated data.

---

## 3\. Which Folders Should Be Deployed in Each Phase?

The existing repository does not need to be redesigned. Use it as a complete codebase while keeping each environment independently deployable.

| Phase | Terraform paths | Action |
| --- | --- | --- |
| Phase 0 | `modules/`, `scripts/`, `policies/` | Validate only |
| Phase 1 | `bootstrap/`, `environments/management/` | Deploy foundation |
| Phase 2 | `modules/security/`, `environments/security/` | Deploy selected controls |
| Phase 3 | `modules/network/`, `environments/network/` | Deploy required networking |
| Phase 4 | `modules/dns/`, `modules/active-directory/`, `modules/transit-gateway/`, `environments/shared-services/` | Deploy as needed |
| Phase 5 — Development | `modules/workloads/dev/`, `environments/workload-dev/` | Deploy when needed |
| Phase 5 — Staging | `modules/workloads/stage/`, `environments/workload-stage/` | Deploy later |
| Phase 6 — Production | `modules/workloads/prod/`, `environments/workload-prod/` | Deploy after validation |
| Optional sandbox | `environments/sandbox/` | Deploy when needed |

Each environment should have a separate Terraform state key.

### Account Creation Strategy

AWS accounts can exist without running application workloads, but they still require account setup, valid email addresses, organizational configuration, and appropriate access controls.

If all eight accounts are required for the initial governance model, create them during Phase 1. Otherwise, create the minimum required member accounts first and add the remaining accounts later.

Keep the target organizational structure documented so that incremental deployment does not result in inconsistent OU or security-policy assignments.

---

## 4\. Phase 0: Validate the Repository Without Deploying

Start from the project root:

```
cd terraform-aws-landing-zone

terraform fmt -recursive
```

Initialize and validate the management root module without configuring a remote backend:

```
terraform -chdir=environments/management init -backend=false

terraform -chdir=environments/management validate
```

Repeat validation for the other root modules as their configuration becomes ready.

These commands assume the root modules and required provider/module dependencies are valid. Backend-disabled initialization is suitable for configuration validation, but it does not test the real remote backend or deployment permissions.

### Recommended Validation Tools

- **TFLint:** Terraform configuration and provider-specific checks.
- **Checkov or Trivy:** Infrastructure-as-code security checks.
- **Terraform plan:** Review proposed infrastructure changes.
- **Pull-request reviews:** Require approval for changes to production, IAM, and security policies.

Do not run `terraform apply` during Phase 0.

Also note that `terraform validate` does not prove that AWS permissions, service quotas, SCPs, routing, or runtime behavior are correct.

---

## 5\. Phase 1: Build the Minimum Foundation

The first actual deployment should have a small and clearly defined scope.

### Required Foundation Components

1. AWS Organizations and the required account/OU structure.
2. IAM Identity Center and administrative access.
3. Terraform remote state in S3 with appropriate security controls.
4. Centralized CloudTrail logging.
5. A tested baseline SCP.
6. AWS Budgets and billing alerts.
7. Consistent resource tagging.
8. Validation of authorized deployment and recovery access.

Do not deploy the full application network, NAT Gateways, Network Firewall, Managed Microsoft AD, or production database unless those components are specifically required for the initial foundation.

### Terraform State Strategy

Maintain separate state files for independently managed layers.

Example S3 state-key structure:

```
s3://<terraform-state-bucket>/
├── management/org.tfstate
├── security/baseline.tfstate
├── network/core.tfstate
├── shared-services/core.tfstate
├── workload-dev/app.tfstate
├── workload-stage/app.tfstate
├── workload-prod/app.tfstate
└── sandbox/core.tfstate
```

This structure is illustrative. The actual S3 object keys must match the backend configuration used by each environment.

### State Backend Requirements

- Enable S3 bucket versioning.
- Encrypt state at rest.
- Restrict state access to authorized deployment roles.
- Use S3 lock files with a compatible Terraform version and backend configuration.
- Document state recovery and backup procedures.
- Avoid storing credentials and other secrets in Terraform state whenever possible.

A `backend.hcl` file configures an existing backend; it does not create the bucket automatically. The bootstrap process must establish the bucket and its security controls before other environments initialize against it.

Terraform state can contain sensitive values. Marking a variable `sensitive` hides normal CLI display but does not automatically remove its value from state.

---

## 6\. How to Deploy One Phase at a Time

Use the same deployment workflow for every environment:

1. Initialize the Terraform backend.
2. Generate a saved Terraform plan.
3. Inspect the proposed changes.
4. Review the expected AWS costs.
5. Apply the plan only after approval.

### Example: Management Foundation

Navigate to the management environment:

```
cd environments/management
```

Initialize the backend:

```
terraform init -backend-config=backend.hcl
```

Generate a saved plan:

```
terraform plan -out=phase1.tfplan
```

Review the proposed changes:

```
terraform show phase1.tfplan
```

After reviewing and approving the plan:

```
terraform apply phase1.tfplan
```

Repeat the process from `environments/security` when deploying the security layer.

Do not run a root-level `deploy-all.sh` during the initial phases.

> **Cost warning:** Terraform plans identify intended infrastructure changes but do not calculate the complete ongoing AWS bill. Use the [AWS Pricing Calculator](<https://calculator.aws/>) alongside each plan.

### Recommended Deployment Controls

- Keep production deployment separate from development and staging.
- Manually review destructive changes, account changes, IAM permissions, and SCP modifications.
- Never automatically approve a plan that deletes or replaces shared infrastructure.
- Do not run concurrent Terraform applies against the same state.
- Do not delete state objects or manually delete managed resources as a cost-saving shortcut.
- Review resource replacement and deletion behavior before applying a plan.

---

## 7\. Important Warnings About Baseline SCPs

The policy files in this repository are starting points, not production-ready security policies. Validate them before attaching them to AWS Organizations OUs.

### Policy Validation Requirements

- **MFA enforcement:** An SCP condition using `aws:MultiFactorAuthPresent` may not enforce the intended behavior for every IAM Identity Center or assumed-role session.
- **Region restrictions:** Account for global AWS services, service-linked operations, and approved exceptions.
- **Encryption enforcement:** The example `kms:GrantId` condition does not reliably enforce customer-managed KMS key encryption for both S3 and EBS.
- **CloudTrail and AWS Config protection:** Prevent unauthorized modification or deletion while permitting approved setup, maintenance, and recovery operations.
- **Administrative recovery:** Maintain a tested recovery path so that an overly restrictive SCP does not prevent legitimate account administration.

### Before Attaching an SCP

1. Validate the policy JSON syntax.
2. Review actions, resources, and conditions against AWS service documentation.
3. Test the policy in a non-production OU or account where practical.
4. Verify that authorized deployment and recovery roles retain the permissions they need.
5. Attach the policy only after review and approval.

> An incorrectly scoped SCP can block Terraform deployments, security tooling, and recovery operations across an entire OU. Apply restrictive policies incrementally and test them before production use.

---

## 8\. Cost-Saving Pre-Deployment Checklist

Complete this checklist before moving from one phase to the next.

### Foundation

- [ ]Confirm account access, Terraform state security, audit logging, and billing alerts.
- [ ]Verify that the foundation can be deployed without launching application workloads.
- [ ]Review the AWS account and OU structure.
- [ ]Validate the baseline SCPs before attaching them.

### Security

- [ ]Identify which security services must be enabled immediately.
- [ ]Estimate AWS Config, GuardDuty, Security Hub, and log-storage costs.
- [ ]Confirm that deferred security services do not create a compliance gap.
- [ ]Configure appropriate audit-log retention and access controls.

### Networking

- [ ]Confirm that an application or on-premises dependency requires a VPN.
- [ ]Determine whether a Virtual Private Gateway is sufficient or a Transit Gateway is required.
- [ ]Defer NAT Gateways and Network Firewall until justified.
- [ ]Estimate network attachment, processing, and data-transfer charges.

### Shared Services

- [ ]Confirm whether managed Active Directory is needed immediately.
- [ ]Deploy Route 53 Resolver endpoints only when required by the DNS architecture.
- [ ]Defer shared services that have no current consumers.

### Workloads

- [ ]Deploy development before staging and production where appropriate.
- [ ]Select appropriately sized compute and database resources.
- [ ]Schedule shutdowns for eligible non-production resources.
- [ ]Verify encryption, backups, and access restrictions before deploying regulated workloads.

### Cost Review

- [ ]Review the Terraform plan before every apply.
- [ ]Estimate recurring AWS costs using the AWS Pricing Calculator.
- [ ]Check resource deletion and replacement behavior.
- [ ]Confirm that budget thresholds and billing notifications are configured.
- [ ]Review actual AWS charges before proceeding to the next phase.

---

## 9\. Recommended Deployment Strategy

Deploy the landing zone in controlled phases rather than provisioning the complete architecture at once.

| Phase | Scope | Deployment decision |
| --- | --- | --- |
| Phase 0 | Repository preparation, validation, and cost estimation | No new infrastructure |
| Phase 1 | Organizations, required accounts, IAM, Terraform state, audit logging, and budgets | Deploy first |
| Phase 2 | Required centralized security controls | Deploy after foundation validation |
| Phase 3 | Minimal VPC and VPN connectivity | Deploy when needed |
| Phase 4 | DNS, Active Directory, and expanded network services | Deploy when dependencies require them |
| Phase 5 | Development and staging workloads | Deploy incrementally |
| Phase 6 | Production workloads and additional security controls | Deploy after readiness review |

The recommended approach is to deploy Phase 1 first, review actual AWS charges, validate the foundation, and then approve Phase 2.

You can prepare all Terraform modules and environment directories in advance without provisioning every resource in the architecture.

---

## 10\. HIPAA-Aligned Production Readiness

Cost optimization must not compromise the security of regulated workloads.

Before storing or processing electronic protected health information (ePHI) in production:

- Verify that the AWS services used are eligible for the intended HIPAA workload.
- Establish required contractual arrangements with AWS, including a Business Associate Addendum where applicable.
- Validate encryption at rest and in transit.
- Enforce least-privilege access and appropriate audit logging.
- Establish backup, recovery, retention, and incident-response procedures.
- Review the architecture and operational controls with the organization's security and compliance teams.

AWS infrastructure alone does not establish HIPAA compliance. The organization must also implement and operate the required administrative, physical, and technical safeguards.

---

## 11\. Final Recommendation

Keep the full Terraform repository ready for future phases, but deploy only what is required now.

Start with account governance, secure Terraform state, identity and access management, centralized audit logging, and cost controls. Add security services, networking, shared services, and application workloads when their requirements are confirmed.

This approach reduces unnecessary recurring costs, limits deployment risk, and preserves a clear path toward the complete enterprise landing zone.

### Cost Estimation Resource

Use the official [AWS Pricing Calculator](<https://calculator.aws/>) to estimate the cost of each deployment phase before provisioning resources.

**Deployment principle:** Prepare everything, deploy selectively, validate continuously, and scale only when the project requires it.

Save as: `terraform-aws-landing-zone/README.md`

The file uses standard Markdown, GitHub-rendered tables, fenced code blocks, and checkboxes. You can edit it in VS Code or any Markdown editor and preview the formatting before committing it to Git.
