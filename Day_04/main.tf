# ==============================================================================
# Day 04: State File Management & Remote Backend (S3 Native State Locking)
# 31 Days of Terraform (AWS)
# ==============================================================================

terraform {
  required_version = ">= 1.10.0"

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

  # ------------------------------------------------------------------------------
  # S3 Remote Backend Configuration with S3 Native State Locking (Terraform 1.10+)
  # ------------------------------------------------------------------------------
  backend "s3" {
    bucket       = "tf-state-day04-938375"
    key          = "dev/day-04/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true # Enables S3 native conditional-write state locking (No DynamoDB required!)
    encrypt      = true # Enables server-side encryption for the state file in S3
  }
}

# ------------------------------------------------------------------------------
# AWS Provider Configuration
# ------------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Day         = "Day_04"
      Project     = var.project_name
    }
  }
}

# ------------------------------------------------------------------------------
# Random ID Generator for Unique Bucket Naming
# ------------------------------------------------------------------------------
resource "random_id" "app_suffix" {
  byte_length = 4
}

# ------------------------------------------------------------------------------
# Sample Managed Infrastructure Resource (S3 Bucket)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "app_data" {
  bucket        = "app-data-day04-${random_id.app_suffix.hex}"
  force_destroy = true

  tags = {
    Name = "app-data-day04-${random_id.app_suffix.hex}"
  }
}

resource "aws_s3_bucket_versioning" "app_data_versioning" {
  bucket = aws_s3_bucket.app_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_data_encryption" {
  bucket = aws_s3_bucket.app_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "app_data_public_access" {
  bucket = aws_s3_bucket.app_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
