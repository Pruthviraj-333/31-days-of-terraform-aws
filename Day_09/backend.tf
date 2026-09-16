# ==============================================================================
# Day 09: Backend Configuration
# 31 Days of Terraform (AWS)
# ==============================================================================

# Remote State Backend (Commented for standalone local development)
# To enable remote state in production, uncomment the backend block below
# and replace the bucket and DynamoDB table with your provisioned state backend.

# terraform {
#   backend "s3" {
#     bucket         = "my-terraform-state-bucket"
#     key            = "day09/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-state-locks"
#     encrypt        = true
#   }
# }
