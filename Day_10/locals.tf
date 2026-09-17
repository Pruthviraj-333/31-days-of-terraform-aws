locals {
  name_prefix = "${var.environment}-${var.project_name}"

  # Conditional sizing based on environment
  instance_type = var.environment == "prod" ? "t3.medium" : (var.environment == "staging" ? "t3.small" : "t3.micro")

  # Conditional instance count based on environment
  instance_count = var.environment == "prod" ? 3 : (var.environment == "staging" ? 2 : 1)

  # Conditional monitoring (always true for prod, configurable for non-prod)
  enable_monitoring = var.environment == "prod" ? true : var.enable_detailed_monitoring

  # Dynamically pick availability zones based on subnet count
  selected_azs = slice(data.aws_availability_zones.available.names, 0, var.public_subnet_count)

  # Conditional tags
  environment_tags = {
    Environment = var.environment
    Region      = var.aws_region
    Tier        = var.environment == "prod" ? "Mission-Critical" : "Non-Production"
    Monitoring  = local.enable_monitoring ? "Enhanced-1Min" : "Basic-5Min"
  }

  common_tags = merge(
    var.resource_tags,
    local.environment_tags
  )
}
