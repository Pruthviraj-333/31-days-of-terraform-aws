# ==============================================================================
# Day 05: Main Resources Implementation
# 31 Days of Terraform (AWS)
# ==============================================================================

# Random string generator for unique suffix
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# S3 Bucket created using inputs and computed local variables
resource "aws_s3_bucket" "demo" {
  bucket        = local.full_bucket_name
  force_destroy = true

  tags = local.common_tags
}

# Enable S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "demo_versioning" {
  bucket = aws_s3_bucket.demo.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable Default Server-Side Encryption (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "demo_encryption" {
  bucket = aws_s3_bucket.demo.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block Public Access for Security
resource "aws_s3_bucket_public_access_block" "demo_public_access" {
  bucket = aws_s3_bucket.demo.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
