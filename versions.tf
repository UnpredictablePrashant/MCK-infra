########################################
# Terraform & Provider Version Requirements
########################################

terraform {
  required_version = ">=1.9, <1.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.23, <7"
    }
  }
}

