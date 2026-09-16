# ==============================================================================
# Day 09: Local Values & Computed Configurations
# 31 Days of Terraform (AWS)
# ==============================================================================

locals {
  name_prefix = "${var.environment}-${var.project_name}"

  common_tags = merge(
    var.resource_tags,
    {
      Environment = var.environment
      Region      = var.aws_region
      CreatedAt   = "Day_09"
    }
  )

  compliance_tags = merge(
    local.common_tags,
    {
      Compliance = var.compliance_framework
      DataClass  = "Confidential"
    }
  )
}
