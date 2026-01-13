########################################
# Terraform & Provider Version Requirements
########################################

terraform {
  required_version = ">=1.9, <1.13"
  cloud {
    hostname     = "terraform.mckinsey.cloud"
     organization = "OFT-MCS-AWS-PLATFORMS"

  }
}