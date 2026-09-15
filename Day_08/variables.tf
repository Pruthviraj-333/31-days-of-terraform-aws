# ==============================================================================
# Day 08: Input Variables
# 31 Days of Terraform (AWS)
# ==============================================================================

variable "aws_region" {
  description = "Primary AWS deployment region (Default Provider)"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "AWS region must follow the standard naming convention (e.g., us-east-1)."
  }
}

variable "secondary_region" {
  description = "Secondary AWS deployment region for disaster recovery (Aliased Provider)"
  type        = string
  default     = "us-west-2"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.secondary_region))
    error_message = "Secondary AWS region must follow the standard naming convention (e.g., us-west-2)."
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
  description = "Project name used for resource naming"
  type        = string
  default     = "day08-meta-args"
}

variable "count_bucket_names" {
  description = "List of bucket category names managed using the count meta-argument"
  type        = list(string)
  default     = ["logs", "media", "backups"]
}

variable "for_each_storage_tiers" {
  description = "Map of storage tiers with specific attributes managed using for_each"
  type = map(object({
    purpose        = string
    versioning     = bool
    lifecycle_days = number
  }))
  default = {
    app-assets = {
      purpose        = "Static web and application media assets"
      versioning     = true
      lifecycle_days = 90
    }
    raw-data = {
      purpose        = "Ingested raw telemetry datasets"
      versioning     = false
      lifecycle_days = 30
    }
    archive = {
      purpose        = "Long-term compliance and audit archives"
      versioning     = true
      lifecycle_days = 365
    }
  }
}

variable "iam_user_names" {
  description = "Set of IAM user names to provision with for_each"
  type        = set(string)
  default     = ["alice-devops", "bob-developer", "charlie-qa"]
}

variable "resource_tags" {
  description = "Common baseline tags applied across all resources"
  type        = map(string)
  default = {
    Owner     = "DevOps-Team"
    ManagedBy = "Terraform"
    Project   = "Terraform-Meta-Arguments"
    Day       = "Day_08"
  }
}
