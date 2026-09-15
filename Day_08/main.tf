# ==============================================================================
# Day 08: Main Infrastructure Definitions
# Comprehensive demonstration of Terraform Meta-Arguments:
# 1. count
# 2. for_each (Sets & Maps)
# 3. depends_on
# 4. lifecycle (create_before_destroy, ignore_changes, prevent_destroy)
# 5. provider (Aliased multi-region provider)
# ==============================================================================

# ------------------------------------------------------------------------------
# Random Suffix Generator for Globally Unique S3 Bucket Names
# ------------------------------------------------------------------------------
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# ==============================================================================
# 1. COUNT META-ARGUMENT DEMONSTRATION
# Creates multiple resources using integer index: aws_s3_bucket.count_buckets[0], [1], [2]
# ==============================================================================
resource "aws_s3_bucket" "count_buckets" {
  count = length(var.count_bucket_names)

  bucket        = "${local.name_prefix}-cnt-${var.count_bucket_names[count.index]}-${random_string.suffix.result}"
  force_destroy = true

  tags = merge(
    local.common_tags,
    {
      Name        = "${local.name_prefix}-cnt-${var.count_bucket_names[count.index]}"
      MetaArg     = "count"
      IndexNumber = tostring(count.index)
      Category    = var.count_bucket_names[count.index]
    }
  )
}

# ==============================================================================
# 2. FOR_EACH META-ARGUMENT DEMONSTRATION (MAP)
# Creates resources using stable string keys: aws_s3_bucket.for_each_buckets["app-assets"], etc.
# ==============================================================================
resource "aws_s3_bucket" "for_each_buckets" {
  for_each = var.for_each_storage_tiers

  bucket        = "${local.name_prefix}-fe-${each.key}-${random_string.suffix.result}"
  force_destroy = true

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-fe-${each.key}"
      MetaArg = "for_each_map"
      TierKey = each.key
      Purpose = each.value.purpose
    }
  )
}

# Conditional Versioning with for_each filtered map
resource "aws_s3_bucket_versioning" "for_each_versioning" {
  for_each = {
    for key, tier in var.for_each_storage_tiers : key => tier if tier.versioning
  }

  bucket = aws_s3_bucket.for_each_buckets[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

# ==============================================================================
# 2B. FOR_EACH META-ARGUMENT DEMONSTRATION (SET)
# Creates IAM users from a unique set of names: aws_iam_user.team_members["alice-devops"]
# ==============================================================================
resource "aws_iam_user" "team_members" {
  for_each = var.iam_user_names

  name          = "${local.name_prefix}-${each.value}"
  force_destroy = true

  tags = merge(
    local.common_tags,
    {
      Name     = "${local.name_prefix}-${each.value}"
      MetaArg  = "for_each_set"
      Username = each.value
    }
  )
}

# ==============================================================================
# 3. DEPENDS_ON META-ARGUMENT DEMONSTRATION
# Enforces explicit dependency ordering in the Directed Acyclic Graph (DAG)
# ==============================================================================
resource "aws_s3_bucket" "central_audit_log" {
  bucket        = "${local.name_prefix}-audit-log-${random_string.suffix.result}"
  force_destroy = true

  # Explicit dependency: Ensure all tier buckets and IAM users exist before creating audit collector
  depends_on = [
    aws_s3_bucket.for_each_buckets,
    aws_s3_bucket.count_buckets,
    aws_iam_user.team_members
  ]

  tags = merge(
    local.common_tags,
    {
      Name        = "${local.name_prefix}-audit-log"
      MetaArg     = "depends_on"
      Description = "Aggregated audit bucket created strictly after primary storage buckets"
    }
  )
}

# ==============================================================================
# 4. LIFECYCLE META-ARGUMENT DEMONSTRATION
# Controls creation order and drift protection
# ==============================================================================
resource "aws_s3_bucket" "lifecycle_demo_bucket" {
  bucket        = "${local.name_prefix}-lifecycle-${random_string.suffix.result}"
  force_destroy = true

  lifecycle {
    # 1. create_before_destroy: Provisions replacements before destroying original
    create_before_destroy = true

    # 2. ignore_changes: Prevents Terraform from reverting out-of-band updates to specific attributes (e.g. external taggers)
    ignore_changes = [
      tags["LastModifiedBy"],
      tags["ExternalTool"]
    ]

    # 3. prevent_destroy: Uncomment in production to guard against accidental deletion via `terraform destroy`
    # prevent_destroy = true
  }

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-lifecycle-bucket"
      MetaArg = "lifecycle"
    }
  )
}

# ==============================================================================
# 5. PROVIDER META-ARGUMENT DEMONSTRATION (MULTI-REGION)
# Routes resource provisioning to an alternate aliased provider (aws.west / us-west-2)
# ==============================================================================
resource "aws_s3_bucket" "dr_secondary_bucket" {
  provider = aws.west

  bucket        = "${local.name_prefix}-dr-west-${random_string.suffix.result}"
  force_destroy = true

  tags = merge(
    local.common_tags,
    {
      Name         = "${local.name_prefix}-dr-secondary-bucket"
      MetaArg      = "provider_alias"
      TargetRegion = var.secondary_region
    }
  )
}
