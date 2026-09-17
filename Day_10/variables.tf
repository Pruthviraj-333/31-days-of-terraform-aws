variable "aws_region" {
  description = "Target AWS deployment region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Project name identifier for resource tagging and naming"
  type        = string
  default     = "day10-expressions"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_count" {
  description = "Number of public subnets to deploy across availability zones"
  type        = number
  default     = 2

  validation {
    condition     = var.public_subnet_count >= 1 && var.public_subnet_count <= 4
    error_message = "Public subnet count must be between 1 and 4."
  }
}

variable "enable_bastion" {
  description = "Conditional feature toggle to provision a dedicated management bastion host"
  type        = bool
  default     = false
}

variable "enable_detailed_monitoring" {
  description = "Feature toggle for EC2 detailed CloudWatch monitoring (overridden to true in prod)"
  type        = bool
  default     = false
}

variable "ingress_rules" {
  description = "List of structured ingress firewall rules processed via dynamic block"
  type = list(object({
    port        = number
    protocol    = string
    description = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      port        = 80
      protocol    = "tcp"
      description = "HTTP web traffic"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      port        = 443
      protocol    = "tcp"
      description = "HTTPS secure web traffic"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      port        = 22
      protocol    = "tcp"
      description = "SSH administrative access"
      cidr_blocks = ["10.0.0.0/16"]
    },
    {
      port        = 8080
      protocol    = "tcp"
      description = "Application server port"
      cidr_blocks = ["10.0.0.0/16"]
    }
  ]
}

variable "egress_rules" {
  description = "List of structured egress firewall rules processed via dynamic block"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all outbound traffic"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "resource_tags" {
  description = "Standard baseline tags applied across all resources"
  type        = map(string)
  default = {
    Owner     = "DevOps-Team"
    ManagedBy = "Terraform"
    Project   = "Dynamic-Blocks-And-Expressions"
    Day       = "Day_10"
  }
}
