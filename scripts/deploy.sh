#!/bin/bash
set -e

# Default values
VERSION="v1.0.0"
REGION="us-east-2"
K8S_DIR="../k8s"
WAIT_FOR_ALB=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --version|-v)
      VERSION="$2"
      shift 2
      ;;
    --region|-r)
      REGION="$2"
      shift 2
      ;;
    --k8s-dir)
      K8S_DIR="$2"
      shift 2
      ;;
    --no-wait)
      WAIT_FOR_ALB=false
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo "Deploy the API to Kubernetes."
      echo ""
      echo "Options:"
      echo "  -v, --version VERSION    Image version tag (default: v1.0.0)"
      echo "  -r, --region REGION      AWS region (default: us-east-2)"
      echo "  --k8s-dir DIRECTORY      Path to the Kubernetes manifests directory (default: ../k8s)"
      echo "  --no-wait                Don't wait for the ALB to be provisioned"
      echo "  -h, --help               Display this help message and exit"
      exit 0
      ;;
    *)
      echo "Error: Unknown option $1"
      exit 1
      ;;
  esac
done

# Move to the terraform directory to get outputs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(cd "$SCRIPT_DIR/../terraform" && pwd)"

echo "Getting EKS cluster info from Terraform outputs..."
cd "$TERRAFORM_DIR"
CLUSTER_NAME=$(terraform output -raw cluster_name)
ECR_REPOSITORY_URL=$(terraform output -raw ecr_repository_url)

if [ -z "$CLUSTER_NAME" ] || [ -z "$ECR_REPOSITORY_URL" ]; then
  echo "Error: Failed to get EKS cluster name or ECR repository URL from Terraform output."
  exit 1
fi

echo "EKS cluster name: $CLUSTER_NAME"
echo "ECR repository URL: $ECR_REPOSITORY_URL"

# Update kubeconfig
echo "Updating kubeconfig for EKS cluster..."
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"

# Check if the challenge-api namespace exists, create it if it doesn't
if ! kubectl get namespace challenge-api &> /dev/null; then
  echo "Creating the 'challenge-api' namespace..."
  kubectl create namespace challenge-api
fi

# Move to the K8S directory
if [ ! -d "$K8S_DIR" ]; then
  echo "Error: Kubernetes manifests directory not found at $K8S_DIR"
  exit 1
fi

# Process and apply all YAML files
echo "Deploying Kubernetes resources..."
for file in "$K8S_DIR"/*.yaml; do
  if [ -f "$file" ]; then
    echo "Processing $file..."
    # Export variables for envsubst
    export ECR_REPOSITORY_URL VERSION
    
    # Use envsubst to replace variables and apply
    envsubst < "$file" | kubectl apply -f -
  fi
done

echo "Kubernetes resources deployed successfully!"

# Wait for the ALB to be provisioned
if [ "$WAIT_FOR_ALB" = true ]; then
  echo "Waiting for the ALB to be provisioned (this can take a few minutes)..."
  
  ATTEMPTS=0
  MAX_ATTEMPTS=30
  SLEEP_SECONDS=20
  
  while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    ALB_URL=$(kubectl get ingress -n challenge-api api-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    
    if [ -n "$ALB_URL" ]; then
      echo "ALB provisioned! Your API is available at: http://$ALB_URL/api/hello"
      break
    fi
    
    ATTEMPTS=$((ATTEMPTS + 1))
    echo "Waiting for ALB to be provisioned... ($ATTEMPTS/$MAX_ATTEMPTS)"
    sleep $SLEEP_SECONDS
  done
  
  if [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; then
    echo "Warning: Timed out waiting for ALB. You can check its status later with:"
    echo "kubectl get ingress -n challenge-api api-ingress"
  fi
fi

# Display resources
echo "Deployed pods:"
kubectl get pods -n challenge-api

echo "Deployed services:"
kubectl get svc -n challenge-api

echo "Deployed ingress:"
kubectl get ingress -n challenge-api
