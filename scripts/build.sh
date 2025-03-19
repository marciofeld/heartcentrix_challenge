#!/bin/bash
set -e

VERSION="v1.0.0"
REGION="us-east-2"
API_DIR="../api"

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
    --api-dir)
      API_DIR="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo "Build and push the API Docker image to ECR."
      echo ""
      echo "Options:"
      echo "  -v, --version VERSION    Image version tag (default: v1.0.0)"
      echo "  -r, --region REGION      AWS region (default: us-east-2)"
      echo "  --api-dir DIRECTORY      Path to the API directory (default: ../api)"
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

echo "Getting ECR repository URL from Terraform outputs..."
cd "$TERRAFORM_DIR"
ECR_REPOSITORY_URL=$(terraform output -raw ecr_repository_url)

if [ -z "$ECR_REPOSITORY_URL" ]; then
  echo "Error: Failed to get ECR repository URL from Terraform output."
  exit 1
fi

echo "ECR repository URL: $ECR_REPOSITORY_URL"

# Move to the API directory
cd "$API_DIR"
if [ ! -f "Dockerfile" ]; then
  echo "Error: Dockerfile not found in $API_DIR"
  exit 1
fi

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$(echo $ECR_REPOSITORY_URL | cut -d'/' -f1)"

# Build the Docker image
echo "Building Docker image: $ECR_REPOSITORY_URL:$VERSION"
docker build -t "$ECR_REPOSITORY_URL:$VERSION" .
docker tag "$ECR_REPOSITORY_URL:$VERSION" "$ECR_REPOSITORY_URL:latest"

# Push the Docker image to ECR
echo "Pushing Docker image to ECR..."
docker push "$ECR_REPOSITORY_URL:$VERSION"
docker push "$ECR_REPOSITORY_URL:latest"

echo "Image $ECR_REPOSITORY_URL:$VERSION has been built and pushed successfully!"
