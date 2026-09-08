Image Updater can monitor registries such as ECR and automatically update the image used by an Argo CD application, with configuration depending on how you manage Git/write-back.

So you essentially have two common approaches:

Approach     	    Who updates image tag?
CI + GitOps     	CI pipeline
Argo CD Image     Updater	Image Updater

For a clean GitOps architecture, I generally recommend the first approach:

CI = build/test/push image
Git = source of truth for desired deployment
Argo CD = continuously reconcile Git → Kubernetes

That gives you a very nice audit trail because every production deployment corresponds to a Git commit.



There are actually three different identity mechanisms involved, and separating them is important:

1)GitHub Actions OIDC → lets GitHub Actions assume an AWS IAM role and push images to ECR. No AWS access keys stored in       GitHub.
2)EKS Pod Identity → lets workloads inside EKS, such as Argo CD Image Updater, access AWS APIs such as ECR.
3)IRSA → older/alternative EKS workload identity mechanism using the cluster's OIDC provider. AWS currently recommends EKS Pod Identity for new EKS workloads where supported.

I would use GitHub OIDC + EKS Pod Identity for a new implementation, and I'll show the IRSA equivalent as well.



