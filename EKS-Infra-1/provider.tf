########################################
# AWS Provider Configuration
########################################

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Project     = "mck"
      Environment = "dev-lab1"
      ManagedBy   = "Terraform"
    }
  }
}
