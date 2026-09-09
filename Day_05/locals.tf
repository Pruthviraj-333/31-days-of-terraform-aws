# ==============================================================================
# Day 05: Local Values (Computed Expressions & Reusable Maps)
# 31 Days of Terraform (AWS)
# ==============================================================================

locals {
  # Common tags consolidated for consistent resource tagging
  common_tags = {
    Environment = var.environment
    Project     = "Terraform-Demo"
    ManagedBy   = "Terraform"
    Day         = "Day_05"
  }

  # Dynamically computed unique S3 bucket name
  full_bucket_name = "${var.environment}-${var.bucket_name}-${random_string.suffix.result}"
}
