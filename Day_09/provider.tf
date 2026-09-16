# ==============================================================================
# Day 09: Terraform Lifecycle Meta-arguments (AWS)
# Provider Configuration and Context Data Sources
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

provider "aws" {
  region = var.aws_region
}

# Current Region Data Source (used for precondition validation)
data "aws_region" "current" {}

# Current Account Identity Data Source
data "aws_caller_identity" "current" {}
