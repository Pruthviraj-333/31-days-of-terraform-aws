# ==============================================================================
# Day 08: Local Values & Computed Expressions
# 31 Days of Terraform (AWS)
# ==============================================================================

locals {
  name_prefix = "${var.environment}-${var.project_name}"

  common_tags = merge(
    var.resource_tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      CreatedAt   = "Day_08"
    }
  )

  # Computed tier count for verification
  total_storage_tiers = length(var.for_each_storage_tiers)
}
