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
###################################################################################
#5. Install AWS Load Balancer Controller
#For production, I would expose Argo CD through an HTTPS AWS ALB, rather than exposing argocd-server directly with a public LoadBalancer.
#I'm assuming your AWS Load Balancer Controller is already installed.
#Check:
###################################################################################
kubectl get deployment \
  -n kube-system \
  aws-load-balancer-controller

If it isn't installed, install it before the Argo ingress step.


#####################################################################################
#6. Install Argo CD using Helm
Add the Helm repository:
#####################################################################################
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

Find available versions:

helm search repo argo/argo-cd --versions | head -20

Choose a specific chart version rather than blindly using whatever happens to be latest:
export ARGOCD_CHART_VERSION="<PIN-A-VERSION>"
Create namespace:

kubectl create namespace argocd


