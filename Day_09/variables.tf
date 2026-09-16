# ==============================================================================
# Day 09: Input Variables
# 31 Days of Terraform (AWS)
# ==============================================================================

variable "aws_region" {
  description = "Target AWS deployment region"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "AWS region must follow the standard naming format (e.g. us-east-1)."
  }
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod", "demo"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, demo."
  }
}

variable "project_name" {
  description = "Project name identifier for resource naming"
  type        = string
  default     = "day09-lifecycle"
}

variable "allowed_regions" {
  description = "List of approved AWS regions for organizational compliance validation"
  type        = list(string)
  default     = ["us-east-1", "us-east-2", "us-west-2", "eu-west-1"]
}

variable "compliance_framework" {
  description = "Compliance standard identifier applied to critical storage (e.g., SOC2, HIPAA, ISO27001)"
  type        = string
  default     = "SOC2"
}

variable "app_version" {
  description = "Application deployment version string to demonstrate replace_triggered_by"
  type        = string
  default     = "1.0.0"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "resource_tags" {
  description = "Standard baseline tags applied across all resources"
  type        = map(string)
  default = {
    Owner     = "DevOps-Team"
    ManagedBy = "Terraform"
    Project   = "Lifecycle-Meta-Arguments"
    Day       = "Day_09"
  }
}
