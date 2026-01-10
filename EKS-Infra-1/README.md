# EKS-Infra-1 (Lab1) Documentation

## 🎯 Overview

**EKS-Infra-1** is the Lab1 environment deployed to AWS Account `0123456789012` with workspace `Srelearn03-labs`.

---

## 📊 Configuration

| Parameter | Value |
|-----------|-------|
| **AWS Account** | 0123456789012 |
| **Workspace** | Srelearn03-labs |
| **Cluster Name** | mck-dev-lab1-eks |
| **VPC CIDR** | 10.1.0.0/16 |
| **Public Subnets** | 10.1.0.0/24, 10.1.1.0/24 |
| **Private Subnets** | 10.1.10.0/24, 10.1.11.0/24 |
| **Name Prefix** | mck-dev-lab1 |
| **Environment** | dev-lab1 |
| **Region** | us-east-1 |
| **Kubernetes Version** | 1.34 |

---

## 🚀 Quick Start

### Deploy Infrastructure

```bash
cd EKS-Infra-1
export TF_WORKSPACE=Srelearn03-labs
terraform init
terraform plan
terraform apply
```

### Access Cluster

```bash
aws eks update-kubeconfig --name mck-dev-lab1-eks --region us-east-1
kubectl get nodes
```

---

## 📦 Components

### VPC
- **CIDR**: 10.1.0.0/16
- **AZs**: us-east-1a, us-east-1b
- **Public Subnets**: 2
- **Private Subnets**: 2
- **NAT Gateway**: Yes
- **Internet Gateway**: Yes

### EKS Cluster
- **Version**: 1.34
- **Authentication**: API_AND_CONFIG_MAP
- **Node Groups**: 2-4 t3.medium instances
- **KMS Encryption**: Enabled
- **Public Endpoint**: Enabled
- **Private Endpoint**: Enabled

### IAM Access Entries
1. **AWS Service Role** - Cluster operations
2. **Infra-lab-EKS** - GitHub Actions deployment
3. **mck-dev-lab1-eks-node-role** - Worker nodes (EC2_LINUX)
4. **admin** - Full cluster administration

### ECR Repositories
- mck-lab1-app
- mck-lab1-api
- mck-lab1-worker

---

## 🔐 IAM Roles

### Required Roles (Must exist before deployment)

```
arn:aws:iam::0123456789012:role/Infra-lab-EKS
arn:aws:iam::0123456789012:role/admin
```

### Created by Terraform

```
arn:aws:iam::0123456789012:role/mck-dev-lab1-eks-cluster-role
arn:aws:iam::0123456789012:role/mck-dev-lab1-eks-node-role
```

---

## 🎯 GitHub Workflow

**File**: `.github/workflows/infra-eks-sre03-lab1.yaml`

**Triggers**:
- Manual: `workflow_dispatch`
- Auto: Push to main when `EKS-Infra-1/` or `modules/` change

**Actions**:
- `plan` - Preview changes
- `apply` - Deploy infrastructure
- `destroy` - Remove infrastructure

---

## 📝 Customization

### Update Node Group Size

Edit `main.tf` around line 263:

```hcl
node_group_min_size       = 2
node_group_desired_size   = 2
node_group_max_size       = 4
```

### Add IAM Access Entry

Edit `main.tf` around line 122:

```hcl
access_entries = {
  # ... existing entries ...
  "arn:aws:iam::0123456789012:role/YOUR-ROLE" = {
    kubernetes_groups = []
    type              = "STANDARD"
  }
}
```

### Restrict Public Access

Edit `main.tf` around line 185:

```hcl
cluster_endpoint_public_access_cidrs = ["YOUR-IP/32"]
```

---

## 🔍 Verification

### Check Infrastructure

```bash
# List resources
terraform state list

# View outputs
terraform output

# Verify cluster
aws eks describe-cluster --name mck-dev-lab1-eks --region us-east-1
```

### Check Access Entries

```bash
aws eks list-access-entries --cluster-name mck-dev-lab1-eks --region us-east-1
```

### Test kubectl Access

```bash
kubectl get nodes
kubectl get pods -A
kubectl auth can-i get pods
```

---

## 🆘 Troubleshooting

### Can't Access Cluster

```bash
# Update kubeconfig
aws eks update-kubeconfig --name mck-dev-lab1-eks --region us-east-1

# Verify IAM identity
aws sts get-caller-identity

# Check access entries
aws eks list-access-entries --cluster-name mck-dev-lab1-eks --region us-east-1
```

### Terraform Errors

```bash
# Reinitialize
terraform init -upgrade

# Validate
terraform validate

# Check workspace
echo $TF_WORKSPACE  # Should be: Srelearn03-labs
```

---

## 📚 Related Documentation

- **Main README**: `../README.md`
- **IAM Guide**: `../IAM-ACCESS-ENTRIES.md`
- **Modules**: `../modules/README.md`
- **Lab2**: `../EKS-Infra-2/README.md`

---

## ✅ Summary

- ✅ Complete EKS infrastructure for Lab1
- ✅ AWS Account: 0123456789012
- ✅ Workspace: Srelearn03-labs
- ✅ IAM Access Entries configured
- ✅ GitHub workflow ready
- ✅ Production-ready security

**Ready to deploy!** 🚀

