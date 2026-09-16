# ==============================================================================
# Day 09: Main Resource Definitions
# Comprehensive demonstration of all 6 Terraform Lifecycle Meta-arguments:
# 1. create_before_destroy
# 2. prevent_destroy
# 3. ignore_changes
# 4. replace_triggered_by
# 5. precondition
# 6. postcondition
# ==============================================================================

# ------------------------------------------------------------------------------
# Random Suffix for Unique S3 Bucket Naming
# ------------------------------------------------------------------------------
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Base VPC used for networking and security group lifecycle demos
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-vpc"
      MetaArg = "lifecycle_base"
    }
  )
}

# ==============================================================================
# 1. CREATE_BEFORE_DESTROY LIFECYCLE RULE
# Creates replacement resource BEFORE destroying old instance (Zero-Downtime)
# ==============================================================================
resource "aws_security_group" "web_sg" {
  name_prefix = "${local.name_prefix}-web-sg-"
  description = "Web security group with zero-downtime replacement lifecycle"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTPS inbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.common_tags,
    {
      Name        = "${local.name_prefix}-web-sg"
      Lifecycle   = "create_before_destroy"
      Description = "Ensures new SG is active before retiring existing SG"
    }
  )
}

# ==============================================================================
# 2. PREVENT_DESTROY LIFECYCLE RULE
# Protects critical production resources against accidental deletion
# ==============================================================================
resource "aws_s3_bucket" "critical_vault" {
  bucket        = "${local.name_prefix}-critical-vault-${random_string.suffix.result}"
  force_destroy = false

  lifecycle {
    # NOTE: Set to true in production. Toggle or comment out when running teardown.
    prevent_destroy = false
  }

  tags = merge(
    local.common_tags,
    {
      Name      = "${local.name_prefix}-critical-vault"
      Lifecycle = "prevent_destroy"
      Tier      = "Critical-Production-Data"
    }
  )
}

# ==============================================================================
# 3. IGNORE_CHANGES LIFECYCLE RULE
# Prevents Terraform from overwriting out-of-band updates from external tools
# ==============================================================================
resource "aws_s3_bucket" "app_data" {
  bucket        = "${local.name_prefix}-app-data-${random_string.suffix.result}"
  force_destroy = true

  lifecycle {
    ignore_changes = [
      tags["LastModifiedBy"],
      tags["ExternalScanner"],
      tags["AutoScalingSync"]
    ]
  }

  tags = merge(
    local.common_tags,
    {
      Name            = "${local.name_prefix}-app-data"
      Lifecycle       = "ignore_changes"
      LastModifiedBy  = "Initial-Deployment"
      ExternalScanner = "Pending-Scan"
    }
  )
}

# ==============================================================================
# 4. REPLACE_TRIGGERED_BY LIFECYCLE RULE
# Triggers resource recreation whenever referenced dependencies update
# ==============================================================================
resource "terraform_data" "app_release" {
  input = var.app_version
}

resource "aws_s3_bucket" "version_triggered_storage" {
  bucket        = "${local.name_prefix}-rel-store-${random_string.suffix.result}"
  force_destroy = true

  lifecycle {
    replace_triggered_by = [
      terraform_data.app_release.output
    ]
  }

  tags = merge(
    local.common_tags,
    {
      Name          = "${local.name_prefix}-release-store"
      Lifecycle     = "replace_triggered_by"
      TargetRelease = var.app_version
    }
  )
}

# ==============================================================================
# 5. PRECONDITION LIFECYCLE RULE
# Validates compliance assertions BEFORE provisioning starts
# ==============================================================================
resource "aws_s3_bucket" "regional_storage" {
  bucket        = "${local.name_prefix}-reg-store-${random_string.suffix.result}"
  force_destroy = true

  lifecycle {
    precondition {
      condition     = contains(var.allowed_regions, data.aws_region.current.name)
      error_message = "Precondition Failed: Deployment region '${data.aws_region.current.name}' is not in approved list: [${join(", ", var.allowed_regions)}]."
    }

    precondition {
      condition     = var.environment != "prod" || can(regex("^10\\.", var.vpc_cidr))
      error_message = "Precondition Failed: Production VPC CIDR must reside within private 10.0.0.0/8 range."
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name      = "${local.name_prefix}-regional-storage"
      Lifecycle = "precondition_validated"
    }
  )
}

# ==============================================================================
# 6. POSTCONDITION LIFECYCLE RULE
# Validates post-provisioning state attributes and compliance guarantees
# ==============================================================================
resource "aws_s3_bucket" "compliance_storage" {
  bucket        = "${local.name_prefix}-compliance-${random_string.suffix.result}"
  force_destroy = true

  tags = local.compliance_tags

  lifecycle {
    postcondition {
      condition     = contains(keys(self.tags), "Compliance")
      error_message = "Postcondition Failed: Resource must contain an explicit 'Compliance' tag."
    }

    postcondition {
      condition     = self.bucket != "" && self.arn != ""
      error_message = "Postcondition Failed: S3 bucket failed to yield valid name or ARN."
    }
  }
}
