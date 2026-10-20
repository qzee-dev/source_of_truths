# Recommended implementation order for your AWS landing zone

Your repository is already organized in a good modular structure. The key is to implement the modules in dependency order, but deploy only the resources needed in each phase.

For your eight-account, HIPAA-aligned AWS landing zone in US East (N. Virginia), with Site-to-Site VPN and a cost-saving approach, I recommend this sequence:

- First: prepare and validate the repository without deploying resources.
- Second: bootstrap AWS Organizations and secure Terraform state.
- Third: establish identity, audit logging, budgets, and carefully tested security guardrails.
- Fourth: deploy the minimum network and VPN components when connectivity is needed.
- Fifth: add shared services and application workloads only when required.

You do not need to implement every module fully before starting. You can build the reusable modules incrementally and leave expensive services disabled until a real dependency requires them.

## 1. The implementation roadmap

### Phase 0 — Preparation

No new infrastructureImplement first · Validate repository and security policies

`README.md`, `.gitignore`, `policies/`, `scripts/validate-landing-zone.sh`, and module skeletons.

### Phase 1 — Bootstrap and organization

First deploymentEstablish administration and state management

`bootstrap/`, `modules/organizations/`, `environments/management/`.

### Phase 2 — Security foundation

Identity, audit logs, baseline guardrails

`modules/security/`, `environments/security/`, `policies/baseline-scp.json`.

### Phase 3 — Minimum networking

Deploy when the first workload or on-premises connection requires it

`modules/network/`, `environments/network/`, then VPN resources.

### Phase 4 — Shared services

Only when there is a confirmed requirement

`modules/dns/`, `modules/active-directory/`, and optionally `modules/transit-gateway/`.

### Phase 5 — Development and staging

Introduce application infrastructure gradually

`modules/workloads/dev/` and `environments/workload-dev/`, then staging.

### Phase 6 — Production

After security, networking, recovery, and cost reviews

`modules/workloads/prod/`, `environments/workload-prod/`, and `policies/prod-scp.json`.

## 2. Exactly which folders come first?

Follow this implementation order. The important distinction is that code implementation order and AWS deployment order are not always the same.

| Order | Folder or file | What you do |
| --- | --- | --- |
| 1 | `README.md`, `.gitignore` | Document the process and protect secrets/state files from Git |
| 2 | `policies/` | Draft and validate SCPs; do not attach them yet |
| 3 | `scripts/validate-landing-zone.sh` | Add formatting, validation, and security checks |
| 4 | `bootstrap/` | Build the organization and state-backend bootstrap procedures |
| 5 | `modules/organizations/` | Implement OUs, account governance, and organization policies |
| 6 | `environments/management/` | Create the management Terraform root and its state configuration |
| 7 | `modules/security/` | Implement logging, security services, and baseline controls |
| 8 | `environments/security/` | Configure centralized security and logging |
| 9 | `modules/network/` | Implement VPCs, subnets, route tables, and VPN prerequisites |
| 10 | `environments/network/` | Deploy only the required network components |
| 11 | `modules/dns/` | Add private DNS when required |
| 12 | `modules/active-directory/` | Add managed directory services only if required |
| 13 | `modules/transit-gateway/` | Add centralized routing when the topology justifies it |
| 14 | `environments/shared-services/` | Deploy the selected shared services |
| 15 | `modules/workloads/dev/` | Implement the development workload |
| 16 | `environments/workload-dev/` | Deploy development |
| 17 | `modules/workloads/stage/` | Implement staging |
| 18 | `environments/workload-stage/` | Deploy staging when needed |
| 19 | `modules/workloads/prod/` | Implement production workloads |
| 20 | `environments/workload-prod/` | Deploy after production readiness approval |
| 21 | `environments/sandbox/` | Add an isolated sandbox only if needed |
| 22 | `scripts/deploy-all.sh` | Consider later, after phased deployments are tested |

You can develop the code for later modules while working on the foundation, but you should not deploy them prematurely.

## 3. Phase 0 — Prepare the repository

Start with the repository root.

bash
```
cd terraform-aws-landing-zone

terraform fmt -recursive
```

Validate each Terraform root independently. For example:

bash
```
terraform -chdir=environments/management init -backend=false
terraform -chdir=environments/management validate
```

Repeat this for other root modules as their configurations become ready.

Implement the following files during this phase:

- `README.md`
- `.gitignore`
- `policies/baseline-scp.json`
- `policies/prod-scp.json`
- `policies/nonprod-scp.json`
- `policies/sandbox-scp.json`
- `scripts/validate-landing-zone.sh`

Keep policy files in source control, but validate their logic before attaching them. JSON syntax validation alone does not establish that an SCP is safe.

Do not run `terraform apply` in Phase 0.

## 4. Phase 1 — Bootstrap, Organizations, and state

This phase establishes the foundation on which the other environments depend.

### Step 1: Implement the bootstrap procedures

Files:

text
```
bootstrap/
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
└── scripts/
    ├── bootstrap-org.sh
    └── bootstrap-state.sh
```

Separate the responsibilities:

- `bootstrap-org.sh`: prepares or verifies AWS Organizations and the initial administrative access.
- `bootstrap-state.sh`: creates the Terraform state backend and configures its security.
- `bootstrap/main.tf`: manages whichever bootstrap resources you choose to manage through Terraform.

Be careful not to make the bootstrap process depend on a remote state bucket that has not been created yet.

For the initial state bootstrap, use a separately secured bootstrap state or a documented local-state procedure followed by a controlled state migration. Do not create the bucket manually and then blindly recreate it with Terraform.

### Step 2: Implement the Organizations module

text
```
modules/organizations/
├── main.tf
├── variables.tf
└── outputs.tf
```

Implement:

- Organizational units
- Member account creation or registration
- Account-to-OU assignments
- SCP attachment resources, initially controlled or disabled until validated

Your eight-account design should have a clear mapping for management, log archive, security tooling, network, production, staging, development, and shared systems. Treat sandbox as optional unless you intend it to be a ninth account.

### Step 3: Implement the management environment

text
```
environments/management/
├── backend.hcl
├── main.tf
├── variables.tf
└── locals.tf
```

This root should call the Organizations module and manage the foundation resources assigned to the management account.

The management account should not become the place where application workloads run.

### Step 4: Verify before moving on

- Confirm the account and OU structure.
- Verify that administrative access works.
- Confirm the state bucket is encrypted, versioned, and access-restricted.
- Test state locking with your chosen Terraform version and S3 backend configuration.
- Configure billing alerts and budgets.
- Test that the deployment role can recover from a failed deployment.

Only proceed after the foundation is recoverable.

## 5. Phase 2 — Security and centralized audit logging

Implement these next:

text
```
modules/security/
├── main.tf
├── variables.tf
└── outputs.tf

environments/security/
├── backend.hcl
├── main.tf
├── variables.tf
└── locals.tf
```

The module should be designed around the controls you actually need, including:

- Centralized CloudTrail logging
- Protected log storage in the log archive account
- AWS Config where required
- GuardDuty and selected Security Hub capabilities
- KMS encryption where appropriate
- Security findings and alert routing

Keep logging and security administration separate from application workloads.

Apply the baseline SCP only after validating its effects. Be particularly careful with region restrictions and policies that deny changes to logging or security services.

Cost-saving decision: enable security services based on the actual compliance and threat requirements. Estimate ingestion, analysis, retention, and per-account charges before enabling them across every account.

Do not defer controls that are prerequisites for protecting regulated data.

## 6. Phase 3 — Network and Site-to-Site VPN

Implement:

text
```
modules/network/
├── main.tf
├── variables.tf
└── outputs.tf

environments/network/
├── backend.hcl
├── main.tf
├── variables.tf
└── locals.tf
```

Start with the smallest topology that satisfies your connectivity requirements:

1. Create the required VPC and private subnets.
2. Configure route tables and security groups.
3. Enable the required network logging.
4. Establish Site-to-Site VPN connectivity if an on-premises system needs access.
5. Restrict routes to only the required destinations.
6. Verify connectivity and failure behavior.

### Should Transit Gateway come now?

Not necessarily.

Start with a Virtual Private Gateway when appropriate

A VPC connected to an on-premises network through Site-to-Site VPN may not need a Transit Gateway initially. A Virtual Private Gateway can be a simpler, lower-cost option for a straightforward topology.

Add Transit Gateway when justified

Introduce `modules/transit-gateway/` when you need centralized routing across multiple VPCs, accounts, or VPN connections and the additional routing capability justifies the recurring cost.

Do not deploy NAT Gateways or AWS Network Firewall just because they appear in the final architecture. First determine the actual internet-egress, inspection, and availability requirements. If they are required by your security design, include their costs rather than removing them solely to save money.

## 7. Phase 4 — DNS, Active Directory, and shared services

Implement these modules independently:

text
```
modules/
├── dns/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── active-directory/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── transit-gateway/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

The shared-services environment should call only the modules required by your design.

| Component | Deploy when |
| --- | --- |
| Private hosted zone | Workloads need internal DNS names |
| Route 53 Resolver endpoints | You need DNS forwarding between AWS and on-premises networks |
| AWS Managed Microsoft AD | Applications require managed directory services or an approved trust design |
| Transit Gateway | Centralized multi-VPC or multi-account routing is needed |

You can prepare all three modules now. You do not need to create all three services in the first deployment.

## 8. Phase 5 — Development first, staging second

Implement development first:

text
```
modules/workloads/dev/
environments/workload-dev/
```

Then add staging:

text
```
modules/workloads/stage/
environments/workload-stage/
```

Use separate state files and separate deployment roles or permissions where appropriate.

For cost savings:

- Use smaller instance and database sizes initially.
- Set storage limits and retention policies.
- Shut down eligible compute resources outside working hours.
- Use managed-service scheduling where supported.
- Review NAT, VPN, logging, and data-transfer charges.
- Prevent development and staging from accessing production networks unless explicitly required.

Your stated non-production schedule is 24/7. Therefore, the baseline estimate should assume those resources remain running around the clock. Scheduled shutdowns would be an optional future saving, not a saving included in the baseline.

## 9. Phase 6 — Production deployment

Implement:

text
```
modules/workloads/prod/
environments/workload-prod/
policies/prod-scp.json
```

Production should be deployed only after you have validated:

- Identity and least-privilege access
- Network segmentation and approved connectivity
- Encryption and key-management requirements
- Audit logging and monitoring
- Backup and recovery procedures
- High availability and failure scenarios
- Cost estimates and budget alerts
- Applicable HIPAA-related service eligibility and contractual requirements

Do not simply copy development settings into production. Production requires its own sizing, availability, recovery, and security decisions.

## 10. How to manage Terraform state and dependencies

Each environment should have an independent state file. For example:

text
```
management/org.tfstate
security/baseline.tfstate
network/core.tfstate
shared-services/core.tfstate
workload-dev/app.tfstate
workload-stage/app.tfstate
workload-prod/app.tfstate
sandbox/core.tfstate
```

Use `terraform_remote_state` only where one environment genuinely needs outputs from another. Grant access to state objects carefully because state can contain sensitive information.

A practical dependency chain is:

mermaid
```
flowchart TD
    A["Phase 0: Validate repository"] --> B["Bootstrap: State and administration"]
    B --> C["Organizations and accounts"]
    C --> D["Security and centralized logging"]
    D --> E["Minimum network and VPN"]
    E --> F["Optional shared services"]
    F --> G["Development workloads"]
    G --> H["Staging workloads"]
    H --> I["Production readiness review"]
    I --> J["Production workloads"]
    C --> K["Optional sandbox account"]
```

This is a logical dependency chain, not a requirement that every component must exist before the next one can be developed. For example, DNS can be implemented later, and a sandbox can be created independently once organizational guardrails are ready.

## 11. Deployment command pattern

For each environment, use the same review process. Example:

bash
```
cd environments/management

terraform init -backend-config=backend.hcl

terraform plan -out=phase1.tfplan

terraform show phase1.tfplan
```

Review the changes, verify the expected charges using the AWS Pricing Calculator, and obtain approval before applying:

bash
```
terraform apply phase1.tfplan
```

Use the equivalent process for security, networking, and workloads. Do not apply all environments in parallel if they depend on outputs or resources that have not yet been created.

A saved plan should be reviewed and applied against the same configuration and state context. If the configuration, state, or deployment assumptions change, generate and review a new plan.

## 12. When should `deploy-all.sh` be implemented?

Implement `scripts/deploy-all.sh` last.

Initially, deploy each environment manually through the approved workflow. Once the individual stages have been tested, the script can orchestrate them in dependency order with:

- Explicit phase selection
- A mandatory plan-review and approval mechanism
- Error handling and stop-on-failure behavior
- Prevention of concurrent operations against the same state
- No automatic approval of destructive changes
- Clear separation between non-production and production
- Logging of execution results

Do not make the script unconditionally apply every module. A phase selector such as `foundation`, `security`, or `network` is safer than an all-or-nothing deployment command.

## My final recommendation

Your first implementation milestone should be Phase 1: Bootstrap + Organizations + management state, followed by the security foundation. Do not begin with Transit Gateway, Active Directory, Network Firewall, or production workloads simply because those directories already exist.

The guiding rule is simple: implement reusable code early, deploy resources only when needed, and promote each phase after its security, cost, and recovery checks pass.
