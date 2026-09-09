# ==============================================================================
# Day 05: Output Variables Definition
# 31 Days of Terraform (AWS)
# ==============================================================================

# Output the created S3 bucket name
output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.demo.bucket
}

# Output the S3 bucket ARN
output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.demo.arn
}

# Output the input variable to confirm the environment value used
output "environment" {
  description = "Environment from input variable"
  value       = var.environment
}

# Output the consolidated tags map from the local variable
output "tags" {
  description = "Tags from local variable"
  value       = local.common_tags
}
