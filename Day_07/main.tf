# ==============================================================================
# Day 07: Main Infrastructure Resources (Consuming Typed Variables)
# 31 Days of Terraform (AWS)
# ==============================================================================

# Random string suffix for globally unique naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# ------------------------------------------------------------------------------
# 1. VPC (Using primitive string CIDR)
# ------------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-vpc"
    }
  )
}

# ------------------------------------------------------------------------------
# 2. Subnets (Iterating over Complex Object List: var.subnet_definitions)
# ------------------------------------------------------------------------------
resource "aws_subnet" "tiers" {
  count = length(var.subnet_definitions)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_definitions[count.index].cidr
  availability_zone       = var.subnet_definitions[count.index].az
  map_public_ip_on_launch = var.subnet_definitions[count.index].is_public

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-${var.subnet_definitions[count.index].name}"
      Tier = var.subnet_definitions[count.index].is_public ? "Public" : "Private"
    }
  )
}

# ------------------------------------------------------------------------------
# 3. Security Group (Using Set/List of Ingress Ports)
# ------------------------------------------------------------------------------
resource "aws_security_group" "web_sg" {
  name_prefix = "${local.name_prefix}-web-sg-"
  description = "Security group with dynamic ingress ports derived from typed set"
  vpc_id      = aws_vpc.main.id

  # Dynamic egress allowing outbound traffic
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-web-sg"
    }
  )
}

# Security Group Rules created per port from set of numbers (converted to string set for for_each)
resource "aws_vpc_security_group_ingress_rule" "ingress_rules" {
  for_each = toset([for port in var.ingress_ports : tostring(port)])

  security_group_id = aws_security_group.web_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
  ip_protocol       = "tcp"
  description       = "Allow inbound traffic on port ${each.value}"
}

# ------------------------------------------------------------------------------
# 4. S3 Bucket (Consuming Object & Boolean Encryption Flag)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "app_storage" {
  bucket        = "${local.name_prefix}-storage-${random_string.suffix.result}"
  force_destroy = true

  tags = merge(
    local.common_tags,
    {
      Name        = "${local.name_prefix}-storage"
      InstanceRef = var.app_server_config.instance_type
    }
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_storage_enc" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.app_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "app_storage_pab" {
  bucket = aws_s3_bucket.app_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
