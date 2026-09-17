output "vpc_id" {
  description = "ID of the provisioned VPC"
  value       = aws_vpc.main.id
}

# 1. Splat Expressions on Subnets
output "public_subnet_ids" {
  description = "List of public subnet IDs extracted via splat expression ([*])"
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks extracted via splat expression ([*])"
  value       = aws_subnet.public[*].cidr_block
}

output "public_subnet_arns" {
  description = "List of public subnet ARNs extracted via splat expression ([*])"
  value       = aws_subnet.public[*].arn
}

# 2. Dynamic Security Group Output
output "security_group_id" {
  description = "ID of the dynamically configured security group"
  value       = aws_security_group.app_sg.id
}

# 3. Splat Expressions on EC2 Instances
output "app_instance_ids" {
  description = "List of EC2 application instance IDs extracted via splat expression ([*])"
  value       = aws_instance.app[*].id
}

output "app_instance_private_ips" {
  description = "List of application instance private IP addresses extracted via splat expression ([*])"
  value       = aws_instance.app[*].private_ip
}

output "app_instance_public_ips" {
  description = "List of application instance public IP addresses extracted via splat expression ([*])"
  value       = aws_instance.app[*].public_ip
}

output "app_instance_arns" {
  description = "List of application instance ARNs extracted via splat expression ([*])"
  value       = aws_instance.app[*].arn
}

# 4. Conditional Output for Bastion Host
output "bastion_host_info" {
  description = "Conditional output showing bastion host public IP if enabled, or a disabled notice"
  value = var.enable_bastion ? {
    status    = "enabled"
    id        = aws_instance.bastion[0].id
    public_ip = aws_instance.bastion[0].public_ip
    } : {
    status    = "disabled"
    id        = "none"
    public_ip = "none"
  }
}

# 5. Expressions Demonstration Summary
output "expressions_demonstration_summary" {
  description = "Summary of dynamic blocks, conditional expressions, and splat expressions applied in Day 10"
  value = {
    environment_evaluation = {
      target_env     = var.environment
      chosen_type    = local.instance_type
      instance_count = local.instance_count
      monitoring     = local.enable_monitoring ? "enabled" : "disabled"
    }
    dynamic_blocks = {
      ingress_rule_count = length(var.ingress_rules)
      egress_rule_count  = length(var.egress_rules)
    }
    splat_extraction = {
      subnet_count   = length(aws_subnet.public[*].id)
      instance_count = length(aws_instance.app[*].id)
    }
  }
}
