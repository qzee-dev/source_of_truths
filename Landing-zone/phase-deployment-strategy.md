## 5. How to deploy one phase at a time

Use the same workflow for every environment. Initialize the backend, inspect the plan, and apply only after reviewing the resources and estimated cost.

For example, for the management foundation:

bash
```
cd environments/management

terraform init -backend-config=backend.hcl

terraform plan -out=phase1.tfplan

terraform show phase1.tfplan
```

After reviewing the plan, apply it only when the changes are approved:

bash
```
terraform apply phase1.tfplan
```

For the security layer, repeat the process from `environments/security`. Do not run a root-level `deploy-all.sh` during the initial phases.

A Terraform plan is not a billing estimate. It shows intended infrastructure changes, but it does not reliably calculate ongoing AWS charges. Use the AWS Pricing Calculator alongside the plan.

### Recommended deployment controls

- Keep production deployment separate from development and staging.
- Review destructive changes, account changes, IAM changes, and SCP changes manually.
- Never automatically approve a plan that deletes or replaces shared infrastructure.
- Do not run multiple Terraform applies against the same state simultaneously.
- Do not remove Terraform state objects or manually delete managed resources as a cost-saving shortcut.

## 6. Important warning about your baseline SCPs

Your policy files are useful starting points, but the sample policies in the blueprint should not be applied unchanged.

For example:

- An MFA SCP condition using `aws:MultiFactorAuthPresent` may not enforce the intended behavior for every IAM Identity Center or assumed-role session.
- A region restriction must account for global services and AWS service-linked operations.
- The sample production policy's `kms:GrantId` condition does not reliably enforce CMK-backed encryption for both S3 and EBS.
- A policy that denies CloudTrail or Config changes must allow the authorized setup and recovery operations needed to manage those services safely.

Validate each policy against AWS Organizations and service-specific policy behavior before attaching it to an OU. An overly restrictive SCP can block your own deployment or recovery process.

## 7. The cost-saving decision checklist

Before each phase, ask these questions:

## Pre-deployment checklist

0 of 6

[ ]FoundationCan account access, state security, audit logging, and budgets be completed without launching workload resources?

[ ]SecurityWhich security services are mandatory now, and which can be enabled later without creating a compliance gap?

[ ]NetworkingDoes an application currently need a VPN, Transit Gateway, NAT Gateway, or Network Firewall?

[ ]Shared servicesDo workloads actually need managed Active Directory or centralized DNS yet?

[ ]WorkloadsCan development run on smaller resources or a schedule before staging and production are introduced?

[ ]Cost reviewHave I reviewed the Terraform plan, expected recurring charges, data-transfer costs, and resource deletion behavior?

My recommendation is to deploy Phase 1 first, then review actual AWS charges before moving to Phase 2. You can prepare all the Terraform modules now without provisioning every component in the architecture.

One final point for a HIPAA-aligned environment: cost-saving deferrals must not leave regulated data unprotected. Before any production workload stores or processes electronic protected health information, validate the applicable AWS service eligibility, required contractual arrangements, security controls, and operational responsibilities with your compliance team.
