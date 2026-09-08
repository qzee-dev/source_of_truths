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

######################################################################
#7. Create secure Argo CD Helm values
#######################################################################
create:
mkdir -p infrastructure/argocd
cd infrastructure/argocd


Create:
values.yaml

for example:
global:
  domain: argocd.example.com

configs:
  params:
    server.insecure: "false"

server:
  replicas: 2

  ingress:
    enabled: true
    controller: aws
    ingressClassName: alb
    hostname: argocd.example.com
    tls: false

    annotations:
      alb.ingress.kubernetes.io/scheme: internal
      alb.ingress.kubernetes.io/target-type: ip
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
      alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:eu-west-1:123456789012:certificate/xxxxxxxx
      alb.ingress.kubernetes.io/ssl-redirect: "443"
      alb.ingress.kubernetes.io/backend-protocol: HTTPS
      alb.ingress.kubernetes.io/healthcheck-protocol: HTTPS
      alb.ingress.kubernetes.io/healthcheck-path: /healthz
      alb.ingress.kubernetes.io/success-codes: "200"

  resources:
    requests:
      cpu: 250m
      memory: 256Mi
    limits:
      cpu: 1
      memory: 1Gi

repoServer:
  replicas: 2

  resources:
    requests:
      cpu: 250m
      memory: 256Mi
    limits:
      cpu: 1
      memory: 1Gi

controller:
  replicas: 1

applicationSet:
  replicas: 2

notifications:
  enabled: true

global:
  networkPolicy:
    create: true
    defaultDenyIngress: true

Important: the exact available Helm values depend on the chart version you pin, so always validate your values against the chart version you're installing. 
The official chart exposes ingress, TLS, service accounts, network policies and other security controls. 

For an internet-facing Argo CD, change:

alb.ingress.kubernetes.io/scheme: internet-facing

But for production, I prefer:



VPN / corporate network
        │
        ▼
Internal ALB
        │
        ▼
Argo CD

unless you have a strong reason to expose Argo publicly.

#######################################################################
#8. Install Argo CD
#######################################################################
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --version "$ARGOCD_CHART_VERSION" \
  --values values.yaml \
  --wait


Check:

kubectl get pods -n argocd

kubectl get ingress -n argocd


You should eventually get something like:

NAME            HOSTS
argocd-server   argocd.example.com

Argo CD's API server serves both HTTPS/gRPC and the web UI, so ingress configuration needs to account for those protocols. 







