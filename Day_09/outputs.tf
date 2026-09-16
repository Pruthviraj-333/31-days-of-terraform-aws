# ==============================================================================
# Day 09: Output Definitions
# Querying all lifecycle-managed AWS infrastructure resources
# ==============================================================================

output "web_security_group_id" {
  description = "ID of the zero-downtime security group (create_before_destroy)"
  value       = aws_security_group.web_sg.id
}

output "critical_vault_bucket_name" {
  description = "Name of the critical data vault bucket (prevent_destroy)"
  value       = aws_s3_bucket.critical_vault.bucket
}

output "critical_vault_bucket_arn" {
  description = "ARN of the critical data vault bucket"
  value       = aws_s3_bucket.critical_vault.arn
}

output "app_data_bucket_name" {
  description = "Name of the app data bucket (ignore_changes)"
  value       = aws_s3_bucket.app_data.bucket
}

output "version_triggered_bucket_name" {
  description = "Name of the storage bucket tied to release versions (replace_triggered_by)"
  value       = aws_s3_bucket.version_triggered_storage.bucket
}

output "regional_storage_bucket_name" {
  description = "Name of the region-verified storage bucket (precondition)"
  value       = aws_s3_bucket.regional_storage.bucket
}

output "compliance_storage_bucket_name" {
  description = "Name of the compliance-guaranteed storage bucket (postcondition)"
  value       = aws_s3_bucket.compliance_storage.bucket
}

output "compliance_storage_tags" {
  description = "Tags verified post-deployment on the compliance bucket"
  value       = aws_s3_bucket.compliance_storage.tags
}

output "lifecycle_demonstration_summary" {
  description = "Summary map of all lifecycle meta-arguments demonstrated in Day 09"
  value = {
    "1_create_before_destroy" = aws_security_group.web_sg.id
    "2_prevent_destroy"       = aws_s3_bucket.critical_vault.bucket
    "3_ignore_changes"        = aws_s3_bucket.app_data.bucket
    "4_replace_triggered_by"  = aws_s3_bucket.version_triggered_storage.bucket
    "5_precondition"          = aws_s3_bucket.regional_storage.bucket
    "6_postcondition"         = aws_s3_bucket.compliance_storage.bucket
  }
}
