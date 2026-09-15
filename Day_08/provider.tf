# ==============================================================================
# Day 08: Terraform Meta-Arguments - Complete Guide
# Provider Configuration with Multi-Region Support
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# Default AWS Provider (Primary Region: us-east-1)
provider "aws" {
  region = var.aws_region
}

# Alternate AWS Provider Configuration (Alias: west / us-west-2)
# Used to demonstrate the 'provider' meta-argument for multi-region architectures
provider "aws" {
  alias  = "west"
  region = var.secondary_region
}
