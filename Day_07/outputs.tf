# ==============================================================================
# Day 07: Output Variable Definitions
# 31 Days of Terraform (AWS)
# ==============================================================================

output "vpc_id" {
  description = "ID of the provisioned VPC (string)"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC (string)"
  value       = aws_vpc.main.cidr_block
}

output "subnet_ids" {
  description = "List of created subnet IDs (list of strings)"
  value       = aws_subnet.tiers[*].id
}

output "subnet_mapping" {
  description = "Map of subnet name to subnet ID (map of strings)"
  value = {
    for idx, subnet in aws_subnet.tiers :
    var.subnet_definitions[idx].name => subnet.id
  }
}

output "security_group_id" {
  description = "ID of the created Security Group (string)"
  value       = aws_security_group.web_sg.id
}

output "allowed_ingress_ports" {
  description = "Configured allowed ingress ports (set of numbers)"
  value       = var.ingress_ports
}

output "app_server_spec" {
  description = "Application server specifications (structured object)"
  value       = var.app_server_config
}

output "s3_bucket_name" {
  description = "Name of the created S3 storage bucket (string)"
  value       = aws_s3_bucket.app_storage.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 storage bucket (string)"
  value       = aws_s3_bucket.app_storage.arn
}

output "common_tags" {
  description = "Merged resource tags (map of strings)"
  value       = local.common_tags
}
