Here is a concise version formatted for a GitHub `README.md`:

 GitHub README — GitOps and Identity Architecture

## Image Updates and GitOps

 Argo CD Image Updater can monitor registries such as Amazon ECR and automatically update image versions used by Argo CD applications. However, there are two common approaches:

 | Approach | Who updates the image tag? |
| --- | --- |
| **CI + GitOps** | CI pipeline |
| **Argo CD Image Updater** | Image Updater |

 For this architecture, we use **CI + GitOps**:

```
CI/CD     → Build, test, and push image to ECR
Git       → Source of truth for the desired image version
Argo CD   → Reconcile Git → Kubernetes
```

 This provides a clear audit trail because every production deployment corresponds to a Git commit.

 ### Identity Architecture

 There are three identity mechanisms to distinguish:

 1. **GitHub Actions OIDC**
   - Allows GitHub Actions to assume AWS IAM roles.
   - Used to authenticate and push application images to ECR.
   - No long-lived AWS access keys are stored in GitHub.
2. **EKS Pod Identity**
   - Allows workloads running inside EKS to access AWS APIs.
   - Can be used by workloads such as Argo CD components that need ECR access.
   - Preferred for new EKS workloads where supported.
3. **IRSA**
   - An alternative EKS workload identity mechanism.
   - Uses the cluster's OIDC provider.
   - Kept as an alternative for workloads or environments where IRSA is required.

Yes. The identity model should be merged into your actual architecture so it is clear **who authenticates to AWS, what role they assume, and what they are allowed to do**.

 Recommended Identity and GitOps Architecture✓

## Recommended Identity and GitOps Architecture

 The deployment architecture separates **application CI**, **container storage**, **GitOps**, and **Kubernetes workload identity**.

```
                    Application Git Repo
                            │
                            │ git push
                            ▼
                     GitHub Actions
                            │
                            │ GitHub OIDC
                            ▼
                 Service-Specific IAM Role
                            │
                            │ ECR push permission
                            │ only for its own repository
                            ▼
                Service-Specific ECR Repository
                            │
                            │ image: <git-sha>
                            ▼
                    Manifest Git Repo
                            │
                            │ desired image version
                            ▼
                         Argo CD
                            │
                            │ reconcile
                            ▼
                           EKS
                            │
                            │ EKS Pod Identity
                            ▼
                    AWS IAM Role (if needed)
                            │
                            │ AWS API access
                            ▼
                    AWS Services such as ECR
```

 ### Identity Responsibilities

 #### 1\. GitHub Actions → AWS

 GitHub Actions uses **GitHub OIDC** to assume a service-specific IAM role.

```
myorg/myapp-auth
       │
       │ GitHub OIDC
       ▼
GitHubActionsECR-auth
       │
       │ Push only
       ▼
myapp/auth
```

 The same pattern is used for every service:

```
myapp-users        → GitHubActionsECR-users
myapp-orders       → GitHubActionsECR-orders
myapp-payments     → GitHubActionsECR-payments
myapp-notifications → GitHubActionsECR-notifications
myapp-catalog      → GitHubActionsECR-catalog
myapp-gateway      → GitHubActionsECR-gateway
myapp-reporting    → GitHubActionsECR-reporting
```

 Each role is restricted to its corresponding ECR repository.

 No long-lived AWS access keys are stored in GitHub.

 #### 2\. CI → ECR

 GitHub Actions builds and pushes an image using the Git commit SHA:

```
123456789012.dkr.ecr.eu-west-1.amazonaws.com/myapp/auth:4f83c91
```

 The CI pipeline then updates the corresponding image tag in the **Manifest Git Repo**.

 #### 3\. Manifest Git Repo → Argo CD

 The manifest repository is the source of truth for the desired Kubernetes state.

 For example:

```
images:
  - name: 123456789012.dkr.ecr.eu-west-1.amazonaws.com/myapp/auth
    newTag: 4f83c91
```

 Argo CD watches this repository and reconciles the desired state into EKS.

```
Manifest Git Repo
       │
       │ Git commit
       ▼
     Argo CD
       │
       ▼
      EKS
```

 #### 4\. EKS → AWS

 For Kubernetes workloads that need to call AWS APIs, use **EKS Pod Identity**.

```
EKS Workload
     │
     │ Pod Identity
     ▼
AWS IAM Role
     │
     ▼
AWS Services
```

 This identity is separate from the GitHub Actions roles.

 ### Separation of Responsibilities

```
GitHub OIDC
    │
    └── CI authentication
          └── Push images to ECR

ECR
    │
    └── Store immutable application images

Git
    │
    └── Desired deployment state

Argo CD
    │
    └── Git → Kubernetes reconciliation

EKS Pod Identity
    │
    └── AWS access for Kubernetes workloads
```

 The key security principle is:

 > **GitHub Actions pushes images; Git stores the desired version; Argo CD deploys it; EKS workloads use Pod Identity when they need AWS access.**

 This keeps CI credentials, container storage, deployment state, and runtime AWS permissions properly separated.
