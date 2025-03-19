# EKS Challenge Project

This project implements a simple API deployed on Amazon EKS (Elastic Kubernetes Service) using Terraform for infrastructure provisioning and Kubernetes for application deployment.

## Project Structure

```
.
├── README.md                 # This file
├── CHALLENGE.md              # The Challenge Description
├── tf_plan_output.txt        # The entire output of the `terraform plan` command
├── curl_test.txt             # The final curl test result against the API
├── api                       # API Application code
│   ├── .dockerignore         # Docker build files exclusion list
│   ├── Dockerfile            # Container image definition
│   ├── app.js                # Node.js Express application
│   └── package.json          # Node.js dependencies
├── k8s                       # Kubernetes manifests
│   ├── deployment.yaml       # API pod deployment configuration
│   ├── ingress.yaml          # Ingress for external access via ALB
│   └── service.yaml          # Service for internal pod networking
├── scripts                   # Helper scripts
│   ├── build.sh              # Build and push Docker image to ECR
│   ├── cleanup.sh            # Clean up resources
│   └── deploy.sh             # Deploy to Kubernetes
└── terraform                 # Infrastructure as Code
    ├── data.tf               # Data sources
    ├── ecr.tf                # ECR repository configuration
    ├── eks.tf                # EKS cluster configuration
    ├── elb.tf                # AWS Load Balancer Controller setup
    ├── iam.tf                # IAM roles and policies
    ├── k8s.tf                # Kubernetes resources
    ├── locals.tf             # Local variables
    ├── outputs.tf            # Terraform outputs
    ├── scripts.tf            # Local provisioners
    ├── security-groups.tf    # Security group definitions
    ├── terraform.tf          # Terraform providers and configuration
    └── vpc.tf                # VPC networking configuration
```

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform 1.3.2+
- Docker installed
- kubectl installed
- AWS account with permissions to create:
  - VPC and networking resources
  - EKS cluster
  - ECR repository
  - IAM roles

## Infrastructure Components

This project creates:
- VPC with public and private subnets
- EKS cluster in private subnets
- ECR repository for container images
- AWS Load Balancer Controller for ingress
- Security groups and IAM roles

## API Details

- Simple Express.js API
- Endpoint `/api/hello` returns "Hello!" 
- Health check at `/health` for Kubernetes probes

## Deployment Steps

### 1. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform apply
```

### 2. Build and Push Docker Image

```bash
# Make the script executable
chmod +x scripts/build.sh

# Build and push the image
./scripts/build.sh
```

### 3. Deploy to Kubernetes

```bash
# Make the script executable
chmod +x scripts/deploy.sh

# Deploy the application
./scripts/deploy.sh
```

### 4. Access the API

After deployment completes, the AWS Load Balancer Controller will provision an Application Load Balancer. You can get the ALB URL with:

```bash
kubectl get ingress -n challenge-api api-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Then access your API at:
```
http://<ALB-URL>/api/hello
```

## Cleaning Up

To clean up all resources:

```bash
# Clean up Kubernetes resources
./scripts/cleanup.sh

# Destroy Terraform resources
cd terraform
terraform destroy
```

## Security Considerations

- EKS cluster is deployed in private subnets
- Public access is only via the ALB
- IAM roles follow principle of least privilege

## Additional Information

The scripts in the `scripts/` directory automate common tasks:
- `build.sh`: Builds and pushes the Docker image to ECR
- `deploy.sh`: Deploys the application to Kubernetes
- `cleanup.sh`: Cleans up resources

For CI/CD integration, consider setting up GitHub Actions workflows to automate this pipeline.