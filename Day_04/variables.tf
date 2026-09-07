# ==============================================================================
# Day 04: Variables Definition
# 31 Days of Terraform (AWS)
# ==============================================================================

variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region for deploying resources"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Target deployment environment (e.g. dev, staging, prod)"
}

variable "project_name" {
  type        = string
  default     = "31-days-of-terraform"
  description = "Project identifier for tagging resources"
}
