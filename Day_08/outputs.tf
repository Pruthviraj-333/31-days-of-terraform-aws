# ==============================================================================
# Day 08: Output Definitions & Advanced Transformation Expressions
# Demonstrates:
# - Splat expressions ([*])
# - For list expressions ([for x in ... : ...])
# - For map expressions ({for k, v in ... : ... => ...})
# - Filtered loop projections (if condition)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Splat Expressions & Count Resource Addressing
# ------------------------------------------------------------------------------
output "count_bucket_names" {
  description = "All bucket names created via count (Splat Expression: [*])"
  value       = aws_s3_bucket.count_buckets[*].bucket
}

output "count_bucket_arns" {
  description = "All bucket ARNs created via count (Splat Expression: [*])"
  value       = aws_s3_bucket.count_buckets[*].arn
}

output "count_bucket_first_id" {
  description = "Individual resource lookup by numeric index [0]"
  value       = aws_s3_bucket.count_buckets[0].id
}

# ------------------------------------------------------------------------------
# 2. For_Each Resource Addressing & Map Projections
# ------------------------------------------------------------------------------
output "for_each_bucket_map" {
  description = "Map projection of tier key to bucket name using for expression"
  value = {
    for tier_key, bucket in aws_s3_bucket.for_each_buckets :
    tier_key => bucket.bucket
  }
}

output "for_each_bucket_arns" {
  description = "Map projection of tier key to bucket ARN"
  value = {
    for tier_key, bucket in aws_s3_bucket.for_each_buckets :
    tier_key => bucket.arn
  }
}

output "versioned_tiers_list" {
  description = "Filtered list of tier names that have versioning enabled"
  value = [
    for tier_key, config in var.for_each_storage_tiers :
    tier_key if config.versioning
  ]
}

# ------------------------------------------------------------------------------
# 3. For_Each IAM Set Addressing
# ------------------------------------------------------------------------------
output "iam_user_arns" {
  description = "Map of IAM usernames to their generated AWS ARNs"
  value = {
    for user, resource in aws_iam_user.team_members :
    user => resource.arn
  }
}

# ------------------------------------------------------------------------------
# 4. Explicit Dependency & Lifecycle Outputs
# ------------------------------------------------------------------------------
output "audit_log_bucket_name" {
  description = "Audit log bucket name (created with explicit depends_on)"
  value       = aws_s3_bucket.central_audit_log.bucket
}

output "lifecycle_bucket_name" {
  description = "Lifecycle-managed bucket name (create_before_destroy & ignore_changes)"
  value       = aws_s3_bucket.lifecycle_demo_bucket.bucket
}

# ------------------------------------------------------------------------------
# 5. Multi-Region Provider Alias Output
# ------------------------------------------------------------------------------
output "dr_secondary_bucket_region" {
  description = "Region of disaster recovery bucket provisioned with aws.west provider"
  value       = aws_s3_bucket.dr_secondary_bucket.region
}

output "dr_secondary_bucket_arn" {
  description = "ARN of disaster recovery bucket in secondary region"
  value       = aws_s3_bucket.dr_secondary_bucket.arn
}
