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

 ### Recommended Identity Model

 For a new implementation:

```
GitHub Actions
      │
      │ GitHub OIDC
      ▼
AWS IAM Role
      │
      │ Push
      ▼
     ECR

EKS Workload
      │
      │ EKS Pod Identity
      ▼
AWS IAM Role
      │
      │ Read/Access
      ▼
     ECR
```

 This keeps **CI authentication** and **EKS workload authentication** separate while avoiding long-lived AWS credentials.
