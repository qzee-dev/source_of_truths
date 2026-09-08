1. Set environment variables

export AWS_REGION=eu-west-1
export CLUSTER_NAME=my-eks-cluster
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity \
  --query Account \
  --output text)

export ARGOCD_NAMESPACE=argocd
export APP_NAMESPACE=myapp

verify:
aws sts get-caller-identity

aws eks update-kubeconfig \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME"

kubectl get nodes

=================================================================
4. Install EKS Pod Identity Agent
For a new EKS setup, I recommend Pod Identity rather than IRSA for workloads inside EKS.

AWS describes Pod Identity as the simpler mechanism because it doesn't require configuring an OIDC identity provider for every cluster. 
Install the EKS add-on:
===========================================================================
aws eks create-addon \
  --cluster-name "$CLUSTER_NAME" \
  --addon-name eks-pod-identity-agent \
  --region "$AWS_REGION"

Check:

aws eks describe-addon \
  --cluster-name "$CLUSTER_NAME" \
  --addon-name eks-pod-identity-agent \
  --region "$AWS_REGION"

And:

kubectl get pods \
  -n kube-system \
  -l app.kubernetes.io/instance=eks-pod-identity-agent

