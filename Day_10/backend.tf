# S3 Remote State Backend Configuration (Day 10)
# Uncomment and configure with your bucket and lock table when running with remote state.

# terraform {
#   backend "s3" {
#     bucket         = "my-terraform-state-bucket"
#     key            = "day10/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
