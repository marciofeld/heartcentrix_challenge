#!/bin/bash
set -e

# Default values
REGION="us-east-2"
K8S_DIR="../k8s"
DESTROY_TERRAFORM=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --region|-r)
      REGION="$2"
      shift 2
      ;;
    --k8s-dir)
      K8S_DIR="$2"
      shift 2
      ;;
    --terraform)
      DESTROY_TERRAFORM=true
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo "Clean up Kubernetes and optionally Terraform resources."
      echo ""
      echo "Options:"
      echo "  -r, --region REGION      AWS region (default: us-east-2)"
      echo "  --k8s-dir DIRECTORY      Path to the Kubernetes manifests directory (default: ../k8s)"
      echo "  --terraform              Also destroy Terraform resources (CAUTION: this will delete all infrastructure)"
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
CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "")

if [ -z "$CLUSTER_NAME" ]; then
  echo "Warning: Failed to get EKS cluster name from Terraform output. Continuing anyway..."
else
  echo "EKS cluster name: $CLUSTER_NAME"
  
  # Update kubeconfig if cluster exists
  echo "Updating kubeconfig for EKS cluster..."
  aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"
fi

# Clean up Kubernetes resources
echo "Removing Kubernetes resources..."

# Check if namespace exists
if kubectl get namespace challenge-api &> /dev/null; then
  echo "Deleting resources in 'challenge-api' namespace..."
  
  # First delete ingress to start ALB cleanup
  kubectl delete ingress -n challenge-api --all --ignore-not-found
  
  # Wait a bit for the ALB to start cleaning up
  echo "Waiting for ALB cleanup to start..."
  sleep 10
  
  # Delete other resources
  kubectl delete service -n challenge-api --all --ignore-not-found
  kubectl delete deployment -n challenge-api --all --ignore-not-found
  kubectl delete configmap -n challenge-api --all --ignore-not-found
  kubectl delete secret -n challenge-api --all --ignore-not-found
  
  echo "Kubernetes resources removed successfully!"
else
  echo "The 'challenge-api' namespace doesn't exist. Skipping Kubernetes cleanup."
fi

# Optionally destroy Terraform resources
if [ "$DESTROY_TERRAFORM" = true ]; then
  echo ""
  echo "CAUTION: You are about to destroy all Terraform-managed infrastructure!"
  echo "This includes the EKS cluster, ECR repository, VPC, and all associated resources."
  echo "This action cannot be undone."
  echo ""
  read -p "Are you sure you want to continue? (yes/no): " CONFIRM
  
  if [ "$CONFIRM" = "yes" ]; then
    echo "Destroying Terraform resources..."
    cd "$TERRAFORM_DIR"
    terraform destroy -auto-approve
    echo "Terraform resources destroyed successfully!"
  else
    echo "Terraform destroy canceled."
  fi
fi

echo "Cleanup complete!"
