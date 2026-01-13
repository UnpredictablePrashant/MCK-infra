# McK Infrastructure Lab - Setup Guide

## Overview

This repository contains Terraform modules for deploying EKS infrastructure on AWS. The deployment is **working directory-based**, meaning Terraform Cloud workflows are triggered based on changes detected in specific working directories (`EKS-Infra-1/` or `EKS-Infra-2/`).

---

## Prerequisites

- AWS Account (Account ID: `669643925277`)
- Terraform Cloud account with access to organization: `OFT-MCS-AWS-PLATFORMS`
- IAM permissions to create roles and OIDC providers
- GitHub repository access: `McK-Internal/McK-Infra-Srelearn02-labs`

---

## Step 1: Create IAM Role for Terraform Cloud

### 1.1 Create the IAM Role

1. Navigate to AWS Console → IAM → Roles
2. Click **Create role**
3. Select **Web identity** as the trusted entity type
4. Configure the OIDC provider:
   - **Identity provider**: `terraform.mckinsey.cloud`
   - **Audience**: `aws.workload.identity`
5. Name the role: `Infra-lab-EKS`
6. Attach the following AWS managed policies (or create a custom policy with required permissions):
   - `AmazonEC2FullAccess`
   - `AmazonEKSClusterPolicy`
   - `AmazonEKSServicePolicy`
   - `AmazonVPCFullAccess`
   - `IAMFullAccess` (or limited IAM permissions)
   - `AmazonEC2ContainerRegistryFullAccess`
   - `AWSKeyManagementServicePowerUser`

### 1.2 Configure Trust Relationship

After creating the role, update the trust relationship to include both GitHub Actions and Terraform Cloud OIDC providers:

1. Go to IAM → Roles → `Infra-lab-EKS`
2. Click on **Trust relationships** tab
3. Click **Edit trust policy**
4. Replace the trust policy with the following:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::669643925277:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": [
                        "repo:McK-Internal/mck-Srelearn02-labs:*",
                        "repo:McK-Internal/mck-Srelearn02-labs:*",
                        "repo:McK-Internal/McK-Infra-Srelearn02-labs:*"
                    ]
                }
            }
        },
        {
            "Sid": "tfe",
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::669643925277:oidc-provider/terraform.mckinsey.cloud"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "terraform.mckinsey.cloud:aud": "aws.workload.identity"
                },
                "StringLike": {
                    "terraform.mckinsey.cloud:sub": "organization:OFT-MCS-AWS-PLATFORMS:project:*:workspace:McK-Infra-Srelearn02-labs:run_phase:*"
                }
            }
        }
    ]
}
```

5. Click **Update policy**

---

## Step 2: Configure Terraform Cloud Workspace

### 2.1 Create/Access Workspace

1. Log in to Terraform Cloud
2. Navigate to organization: `OFT-MCS-AWS-PLATFORMS`
3. Access or create workspace: `McK-Infra-Srelearn02-labs`

### 2.2 Configure Workspace Variables

Add the following **environment variables** to enable OIDC authentication:

| Key                      | Value                                                | Category | Description                                    |
|--------------------------|------------------------------------------------------|----------|------------------------------------------------|
| `TFC_AWS_PROVIDER_AUTH`  | `true`                                               | env      | Enables AWS provider authentication via OIDC  |
| `TFC_AWS_RUN_ROLE_ARN`   | `arn:aws:iam::669643925277:role/Infra-lab-EKS`      | env      | IAM role ARN for Terraform Cloud to assume    |

**Steps to add variables:**

1. In your workspace, click **Variables**
2. Under **Environment Variables**, click **Add variable**
3. Add each variable with the key, value, and category as shown above
4. Mark both as **Environment variable** (not Terraform variable)
5. Click **Save variable**

---

## Step 3: Working Directory-Based Deployment

### How It Works

Terraform Cloud is configured to monitor specific working directories for changes:

- **`EKS-Infra-1/`** - Lab 1 infrastructure
- **`EKS-Infra-2/`** - Lab 2 infrastructure

When you commit changes to files within these directories, Terraform Cloud automatically:

1. Detects the changes
2. Triggers a plan/apply workflow
3. Uses the IAM role configured in workspace variables
4. Deploys infrastructure based on the modified working directory

### Deployment Trigger

- **Automatic**: Push changes to the repository in the respective working directory
- **Manual**: Trigger runs manually from Terraform Cloud console

---

## Step 4: How to Call Modules

### Module Structure

The repository contains the following reusable modules in the `modules/` directory:

- **vpc** - VPC, subnets, NAT gateways, route tables
- **kms** - KMS encryption keys (auto-named with prefix)
- **iam** - IAM roles for EKS cluster and nodes (auto-named with prefix)
- **eks** - EKS cluster and node groups (uses IAM module outputs)
- **ecr** - ECR repositories (auto-named with prefix)

**Key Design Feature**: All modules use a consistent `name_prefix` variable to automatically name resources, allowing multiple users to provision infrastructure in the same AWS account without naming conflicts.

### Quick Reference - Required Module Variables

| Module | Required Variables | Auto-Named Resources |
|--------|-------------------|---------------------|
| **vpc** | `name`, `cidr_block`, `azs`, `public_subnets`, `private_subnets`, `product_id`, `used_for` | VPC, Subnets, NAT Gateways, Route Tables |
| **kms** | `name_prefix`, `product_id`, `used_for` | KMS Key: `{prefix}-kms-key`, Alias: `alias/{prefix}-eks-encryption` |
| **iam** | `name_prefix`, `product_id`, `used_for` | Cluster Role: `{prefix}-eks-cluster-role`, Node Role: `{prefix}-eks-node-role`, Instance Profile: `{prefix}-eks-node-profile` |
| **eks** | `cluster_name`, `vpc_id`, `private_subnet_ids`, `cluster_role_arn`, `node_role_arn`, `kms_key_arn`, `product_id`, `used_for` | EKS Cluster, Node Groups |
| **ecr** | `name_prefix`, `repository_suffixes`, `kms_key_id`, `product_id`, `used_for` | Repositories: `{prefix}-{suffix}` (e.g., `mck-dev-lab1-app`) |

**Note**: The `name_prefix` should be unique for each user/environment (e.g., `john-dev-lab1`, `jane-prod-app2`).

### Calling Modules - Example Configuration

Below is an example of how to call all modules in your working directory's `main.tf`:

```hcl
########################################
# Local Values
########################################

locals {
  name_prefix = "mck-dev-lab1"
  product_id  = "19497"
  used_for    = "non-prod"

  common_tags = {
    Project     = "mck"
    Environment = "dev-lab1"
    ManagedBy   = "Terraform"
  }
}

########################################
# VPC Module
########################################

module "vpc" {
  source = "../modules/vpc"

  name       = local.name_prefix
  cidr_block = "10.1.0.0/16"
  azs        = ["us-east-1a", "us-east-1b"]

  public_subnets  = ["10.1.0.0/24", "10.1.1.0/24"]
  private_subnets = ["10.1.10.0/24", "10.1.11.0/24"]

  # Feature toggles
  enable_vpc              = true
  enable_internet_gateway = true
  enable_nat_gateway      = true
  enable_route_tables     = true
  enable_security_group   = false

  # Mandatory tags
  product_id = local.product_id
  used_for   = local.used_for

  tags = local.common_tags
}

########################################
# KMS Module
########################################

module "kms" {
  source = "../modules/kms"

  name_prefix              = local.name_prefix
  kms_key_description      = "KMS key for MCK EKS Lab1 cluster encryption"
  kms_deletion_window_days = 10
  kms_enable_key_rotation  = true

  # Mandatory tags
  product_id = local.product_id
  used_for   = local.used_for

  tags = local.common_tags
}

########################################
# IAM Module
########################################

module "iam" {
  source = "../modules/iam"

  depends_on = [module.kms]

  name_prefix   = local.name_prefix
  region        = "us-east-1"
  iam_role_path = "/"

  # Mandatory tags
  product_id = local.product_id
  used_for   = local.used_for

  tags = local.common_tags
}

########################################
# EKS Module
########################################

module "eks" {
  source = "../modules/eks"

  depends_on = [module.vpc, module.iam, module.kms]

  region          = "us-east-1"
  cluster_name    = "${local.name_prefix}-eks"
  cluster_version = "1.34"

  # Network configuration from VPC module
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # Use IAM roles from IAM module
  create_iam_roles = false
  cluster_role_arn = module.iam.eks_cluster_role_arn
  node_role_arn    = module.iam.eks_node_role_arn

  # KMS Encryption - use KMS key from KMS module
  kms_key_arn = module.kms.kms_key_arn

  # EKS Configuration
  enable_auto_mode    = false
  authentication_mode = "API_AND_CONFIG_MAP"

  # IAM Access Entries
  enable_iam_access_entries      = true
  create_standard_access_entries = true

  access_entries = {
    "arn:aws:iam::669643925277:role/admin" = {
      kubernetes_groups = []
      type              = "STANDARD"
    }
  }

  access_entry_policy_associations = {
    "admin-cluster-admin" = {
      principal_arn = "arn:aws:iam::669643925277:role/admin"
      policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      access_scope = {
        type = "cluster"
      }
    }
  }

  # API Access
  enable_public_access                 = true
  enable_private_access                = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  # Security Group
  create_cluster_security_group = true

  cluster_security_group_ingress_rules = [
    {
      description = "EKS API access from VPC"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["10.1.0.0/16"]
    }
  ]

  allow_all_cluster_egress = true

  # Node Group Configuration
  node_group_min_size       = 2
  node_group_desired_size   = 2
  node_group_max_size       = 4
  node_group_instance_types = ["t3.medium"]
  node_group_capacity_type  = "ON_DEMAND"
  node_group_disk_size      = 20

  node_group_labels = {
    environment = "dev-lab1"
  }

  # Mandatory tags
  product_id = local.product_id
  used_for   = local.used_for

  tags = local.common_tags
}

########################################
# ECR Module
########################################

module "ecr" {
  source = "../modules/ecr"

  depends_on = [module.kms]

  name_prefix             = local.name_prefix
  repository_suffixes     = ["app", "api", "worker"]
  image_tag_mutability    = "MUTABLE"
  scan_on_push            = true
  enable_encryption       = true
  kms_key_id              = module.kms.kms_key_id
  enable_lifecycle_policy = true
  image_expiration_days   = 7
  max_image_count         = 10

  # Mandatory tags
  product_id = local.product_id
  used_for   = local.used_for

  tags = local.common_tags
}
```

### Automatic Resource Naming

All modules use the `name_prefix` variable to automatically generate consistent resource names. This eliminates the need to manually specify individual resource names and prevents naming conflicts when multiple users provision infrastructure in the same AWS account.

**Example with `name_prefix = "mck-dev-lab1"`:**

- **KMS Key**: `mck-dev-lab1-kms-key`
- **KMS Alias**: `alias/mck-dev-lab1-eks-encryption`
- **Cluster IAM Role**: `mck-dev-lab1-eks-cluster-role`
- **Node IAM Role**: `mck-dev-lab1-eks-node-role`
- **Node Instance Profile**: `mck-dev-lab1-eks-node-profile`
- **IAM Policies**: `mck-dev-lab1-eks-cluster-kms-policy`, `mck-dev-lab1-eks-node-vpc-policy`, etc.
- **EKS Cluster**: `mck-dev-lab1-eks`
- **ECR Repositories**: `mck-dev-lab1-app`, `mck-dev-lab1-api`, `mck-dev-lab1-worker`

**Benefits:**
- **No Name Conflicts**: Each user can use a unique prefix (e.g., `john-dev-lab1`, `jane-dev-lab2`)
- **Simplified Module Calls**: Just pass one `name_prefix` instead of multiple individual names
- **Consistent Naming**: All resources follow the same pattern automatically
- **Easy Identification**: Resources are easily identifiable by their prefix

### Module Calling Best Practices

1. **Use unique `name_prefix`** for each environment/user (e.g., `<username>-dev-lab1`)
2. **Use relative paths** for module sources (e.g., `../modules/vpc`)
3. **Set dependencies** using `depends_on` to ensure proper resource creation order
4. **Pass outputs** between modules (e.g., VPC outputs to EKS module, KMS key ID to ECR)
5. **Use locals** for common values like name prefixes and tags
6. **Tag consistently** with `product_id`, `used_for`, and custom tags

---

## Step 5: Deploy Infrastructure

### Multi-User Setup (Important!)

When multiple users are deploying to the same AWS account, **each user MUST use a unique `name_prefix`** in their working directory's `locals` block to avoid resource naming conflicts.

**Example for multiple users:**

```hcl
# User 1: EKS-Infra-1/main.tf
locals {
  name_prefix = "john-dev-lab1"  # Unique prefix for John
  # ...
}

# User 2: EKS-Infra-2/main.tf  
locals {
  name_prefix = "jane-dev-lab2"  # Unique prefix for Jane
  # ...
}
```

This ensures that:
- All KMS keys, IAM roles, EKS clusters, and ECR repositories have unique names
- Users can deploy independently without conflicts
- Resources are easily identifiable by their owner

### Initial Deployment

1. **Update `name_prefix`** in `EKS-Infra-1/main.tf` or `EKS-Infra-2/main.tf` with your unique identifier:
   ```hcl
   locals {
     name_prefix = "your-username-dev-lab1"  # Change this!
     # ...
   }
   ```

2. Commit and push changes to the repository:
   ```bash
   git add .
   git commit -m "Initial infrastructure setup for your-username"
   git push origin main
   ```

3. Terraform Cloud will automatically detect changes in the working directory
4. Review the plan in Terraform Cloud console
5. Approve and apply the changes

### Subsequent Updates

- Any changes to files in the working directories will trigger automatic plans
- Review and approve plans in Terraform Cloud
- Terraform will use the IAM role configured in workspace variables

---

## Step 6: Verify Deployment

### Check Terraform Cloud

1. Navigate to your workspace in Terraform Cloud
2. View the run history and status
3. Check for successful plan/apply

### Check AWS Console

1. **VPC**: Verify VPC, subnets, route tables, NAT gateways
2. **KMS**: Verify KMS key creation and alias
3. **IAM**: Verify EKS cluster and node roles
4. **EKS**: Verify EKS cluster and node groups
5. **ECR**: Verify ECR repositories

### Access EKS Cluster

```bash
# Update kubeconfig (replace with your actual cluster name based on your name_prefix)
aws eks update-kubeconfig --region us-east-1 --name <your-name-prefix>-eks

# Example for name_prefix "mck-dev-lab1":
aws eks update-kubeconfig --region us-east-1 --name mck-dev-lab1-eks

# Verify cluster access
kubectl get nodes
kubectl get pods --all-namespaces
```

---

## Step 7: Access Your EKS Cluster

Once your infrastructure is deployed, follow these steps to access and interact with your EKS cluster.

### Prerequisites

1. **AWS CLI** - Installed and configured
2. **kubectl** - Kubernetes command-line tool installed
3. **IAM Permissions** - Your IAM user/role must be configured in the EKS cluster access entries

### Step 7.1: Configure AWS CLI

Ensure your AWS CLI is configured with credentials:

```bash
# Check current AWS identity
aws sts get-caller-identity

# Expected output shows your account ID and IAM principal
# {
#     "UserId": "AIDAXXXXXXXXXXXXXXXXX",
#     "Account": "669643925277",
#     "Arn": "arn:aws:iam::669643925277:role/admin"
# }
```

### Step 7.2: Update Kubeconfig

Download the cluster configuration to your local kubeconfig file:

```bash
# Replace <your-name-prefix> with your actual prefix
aws eks update-kubeconfig --region us-east-1 --name <your-name-prefix>-eks --alias <your-name-prefix>

# Example for name_prefix "mck-dev-lab1":
aws eks update-kubeconfig --region us-east-1 --name mck-dev-lab1-eks --alias mck-dev-lab1
```

**Expected Output:**
```
Added new context mck-dev-lab1 to /Users/username/.kube/config
```

### Step 7.3: Verify Cluster Access

Test your connection to the cluster:

```bash
# 1. Check cluster info
kubectl cluster-info

# 2. List all nodes
kubectl get nodes

# Expected output:
# NAME                         STATUS   ROLES    AGE   VERSION
# ip-10-1-10-xxx.ec2.internal  Ready    <none>   5m    v1.34.x
# ip-10-1-11-xxx.ec2.internal  Ready    <none>   5m    v1.34.x

# 3. Check node details
kubectl get nodes -o wide

# 4. List all pods across all namespaces
kubectl get pods --all-namespaces

# 5. Check cluster resources
kubectl get all --all-namespaces
```

### Step 7.4: Verify IAM Access Entry

Check if your IAM principal has proper access configured:

```bash
# List access entries (requires AWS CLI)
aws eks list-access-entries --cluster-name <your-name-prefix>-eks --region us-east-1

# Describe your specific access entry
aws eks describe-access-entry \
  --cluster-name <your-name-prefix>-eks \
  --principal-arn arn:aws:iam::669643925277:role/admin \
  --region us-east-1
```

### Step 7.5: Common kubectl Commands

```bash
# Create a namespace
kubectl create namespace demo

# Deploy a sample application
kubectl create deployment nginx --image=nginx -n demo

# Expose the deployment
kubectl expose deployment nginx --port=80 --type=LoadBalancer -n demo

# Check deployment status
kubectl get deployments -n demo
kubectl get pods -n demo
kubectl get services -n demo

# View logs
kubectl logs -f deployment/nginx -n demo

# Delete resources
kubectl delete namespace demo
```

### Step 7.6: Switch Between Clusters (Multiple Users)

If you have multiple clusters configured:

```bash
# List all available contexts
kubectl config get-contexts

# Switch to a specific cluster context
kubectl config use-context <your-name-prefix>

# Example:
kubectl config use-context mck-dev-lab1

# View current context
kubectl config current-context
```

### Step 7.7: Deploy Sample Application

Test your cluster with a complete application deployment:

```bash
# Create a deployment
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-app
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello
  template:
    metadata:
      labels:
        app: hello
    spec:
      containers:
      - name: hello
        image: gcr.io/google-samples/hello-app:1.0
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: hello-service
  namespace: default
spec:
  type: LoadBalancer
  selector:
    app: hello
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
EOF

# Wait for the LoadBalancer to be provisioned (may take 2-3 minutes)
kubectl get service hello-service --watch

# Once EXTERNAL-IP is assigned, test the application
curl http://<EXTERNAL-IP>

# Clean up
kubectl delete deployment hello-app
kubectl delete service hello-service
```

### Troubleshooting Cluster Access

#### Issue: "error: You must be logged in to the server (Unauthorized)"

**Solution:**
1. Verify your IAM principal is in the access entries:
   ```bash
   aws eks list-access-entries --cluster-name <your-name-prefix>-eks --region us-east-1
   ```

2. Check if you're using the correct AWS credentials:
   ```bash
   aws sts get-caller-identity
   ```

3. If your role is missing, add it to the `access_entries` in your `main.tf`:
   ```hcl
   access_entries = {
     "arn:aws:iam::669643925277:role/your-role" = {
       kubernetes_groups = []
       type              = "STANDARD"
     }
   }
   ```

#### Issue: "Unable to connect to the server"

**Solution:**
1. Check cluster endpoint is accessible:
   ```bash
   aws eks describe-cluster --name <your-name-prefix>-eks --region us-east-1 --query 'cluster.endpoint'
   ```

2. Verify security group allows your IP:
   - Check `cluster_endpoint_public_access_cidrs` in your configuration
   - Ensure your public IP is allowed

#### Issue: "The connection to the server was refused"

**Solution:**
- Cluster may still be provisioning. Wait a few minutes and try again.
- Check cluster status:
  ```bash
  aws eks describe-cluster --name <your-name-prefix>-eks --region us-east-1 --query 'cluster.status'
  ```

---

## Troubleshooting

### Issue: Terraform Cloud cannot assume role

**Solution**: 
- Verify trust relationship in IAM role includes Terraform Cloud OIDC provider
- Ensure workspace variables are set correctly
- Check workspace name matches the trust policy condition

### Issue: Deployment fails with permission errors

**Solution**:
- Verify IAM role has required AWS managed policies attached
- Check that role ARN in workspace variables is correct

### Issue: Changes not triggering workflow

**Solution**:
- Ensure changes are in the correct working directory (`EKS-Infra-1/` or `EKS-Infra-2/`)
- Verify VCS connection in Terraform Cloud workspace settings
- Check workspace is configured to monitor the correct working directories

---

## Important Notes

- **Unique Name Prefix Required**: Each user MUST use a unique `name_prefix` (e.g., `username-dev-lab1`) to avoid resource naming conflicts in the same AWS account
- **Automatic Resource Naming**: All resources (KMS keys, IAM roles, ECR repos, etc.) are automatically named using the `name_prefix` - no manual naming needed
- **Working Directory Based**: Terraform workflows trigger based on changes in `EKS-Infra-1/` or `EKS-Infra-2/` directories only
- **No GitHub Actions**: This setup uses Terraform Cloud, not GitHub Actions workflows
- **OIDC Authentication**: Uses workload identity federation (no static credentials)
- **Multi-Account Support**: Trust relationship supports both GitHub and Terraform Cloud OIDC providers
- **Module Reusability**: All modules in `modules/` directory are reusable across different environments and users

---

## Support

For issues or questions:
- Check Terraform Cloud run logs for detailed error messages
- Review AWS CloudTrail for IAM/permission issues
- Verify all prerequisites are met before deployment
