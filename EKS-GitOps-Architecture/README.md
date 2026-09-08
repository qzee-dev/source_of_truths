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

