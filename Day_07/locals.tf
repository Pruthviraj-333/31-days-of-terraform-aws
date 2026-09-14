# ==============================================================================
# Day 07: Local Value Transformations & Type Manipulations
# 31 Days of Terraform (AWS)
# ==============================================================================

locals {
  # Merged tags incorporating environment and computed properties
  common_tags = merge(
    var.resource_tags,
    {
      Environment = var.environment
      Region      = var.aws_region
    }
  )

  # Computed naming prefix based on environment and string variables
  name_prefix = "${var.environment}-day07"

  # Convert set of ingress ports to a sorted list for predictable order
  sorted_ingress_ports = sort([for port in var.ingress_ports : tostring(port)])

  # Extract public subnets from the complex object list
  public_subnets = [
    for subnet in var.subnet_definitions : subnet if subnet.is_public
  ]

  # Extract private subnets from the complex object list
  private_subnets = [
    for subnet in var.subnet_definitions : subnet if !subnet.is_public
  ]
}
