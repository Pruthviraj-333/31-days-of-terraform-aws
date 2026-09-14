# ==============================================================================
# Day 07: Type Constraints & Validation Rules
# 31 Days of Terraform (AWS)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Primitive Types (string, number, bool)
# ------------------------------------------------------------------------------

variable "aws_region" {
  description = "Target AWS deployment region"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "AWS region must follow valid format (e.g. us-east-1, eu-west-1)."
  }
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production", "demo"], var.environment)
    error_message = "Environment must be one of: dev, staging, production, demo."
  }
}

variable "vpc_cidr" {
  description = "Base IPv4 CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block (e.g. 10.0.0.0/16)."
  }
}

variable "instance_count" {
  description = "Number of EC2 instances to provision"
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be an integer between 1 and 10."
  }
}

variable "enable_encryption" {
  description = "Flag to enforce server-side AES256 encryption on S3 and EBS"
  type        = bool
  default     = true
}

# ------------------------------------------------------------------------------
# 2. Collection Types (list, set, map)
# ------------------------------------------------------------------------------

variable "availability_zones" {
  description = "Ordered list of AWS availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two availability zones must be specified for high availability."
  }
}

variable "ingress_ports" {
  description = "Unordered set of unique ingress port numbers for Security Group"
  type        = set(number)
  default     = [80, 443, 22]
}

variable "resource_tags" {
  description = "Key-value map of standardized tags to apply to all resources"
  type        = map(string)
  default = {
    Owner       = "DevOps-Team"
    ManagedBy   = "Terraform"
    Project     = "Type-Constraints-Demo"
    Day         = "Day_07"
  }
}

# ------------------------------------------------------------------------------
# 3. Structural Types (tuple, object)
# ------------------------------------------------------------------------------

variable "network_spec" {
  description = "Fixed-length, mixed-type tuple: [Subnet Name Prefix, Subnet CIDR Offset, Public IP Enabled]"
  type        = tuple([string, number, bool])
  default     = ["public-app", 1, true]
}

variable "app_server_config" {
  description = "Complex structured object defining application server specifications"
  type = object({
    instance_type = string
    disk_size_gb  = number
    monitoring    = bool
    backup_retention_days = number
  })
  default = {
    instance_type         = "t3.micro"
    disk_size_gb          = 20
    monitoring            = true
    backup_retention_days = 7
  }

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium", "t2.micro"], var.app_server_config.instance_type)
    error_message = "Instance type must be a standard development class (t3.micro, t3.small, t3.medium, t2.micro)."
  }

  validation {
    condition     = var.app_server_config.disk_size_gb >= 10 && var.app_server_config.disk_size_gb <= 100
    error_message = "Disk size must be between 10 GB and 100 GB."
  }
}

variable "subnet_definitions" {
  description = "List of structured objects defining multi-tier subnets"
  type = list(object({
    name = string
    cidr = string
    az   = string
    is_public = bool
  }))
  default = [
    {
      name      = "public-web-1"
      cidr      = "10.0.1.0/24"
      az        = "us-east-1a"
      is_public = true
    },
    {
      name      = "private-app-1"
      cidr      = "10.0.2.0/24"
      az        = "us-east-1b"
      is_public = false
    }
  ]
}
