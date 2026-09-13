# ==============================================================================
# Day 06: Provider Configuration
# 31 Days of Terraform (AWS)
# ==============================================================================

provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}
