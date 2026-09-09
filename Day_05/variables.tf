# ==============================================================================
# Day 05: Input Variables Definition
# 31 Days of Terraform (AWS)
# ==============================================================================

variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Target deployment environment (e.g. dev, staging, prod, demo)"
  type        = string
  default     = "staging"
}

variable "bucket_name" {
  description = "Base name for the S3 bucket"
  type        = string
  default     = "my-terraform-bucket"
}
