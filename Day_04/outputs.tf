# ==============================================================================
# Day 04: Outputs Definition
# 31 Days of Terraform (AWS)
# ==============================================================================

output "sample_bucket_id" {
  description = "The name of the sample S3 bucket managed via remote state"
  value       = aws_s3_bucket.app_data.id
}

output "sample_bucket_arn" {
  description = "The ARN of the sample S3 bucket managed via remote state"
  value       = aws_s3_bucket.app_data.arn
}

output "random_suffix_hex" {
  description = "The hex string generated for unique naming"
  value       = random_id.app_suffix.hex
}
