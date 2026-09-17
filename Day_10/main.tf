resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# 1. VPC Infrastructure
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-vpc-${random_string.suffix.result}"
      Pattern = "conditional_vpc"
    }
  )
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-igw-${random_string.suffix.result}"
    }
  )
}

# 2. Public Subnets across multiple AZs
resource "aws_subnet" "public" {
  count                   = var.public_subnet_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone       = local.selected_azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-public-subnet-${count.index + 1}"
      AZ   = local.selected_azs[count.index]
      Tier = "Public"
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-public-rt"
    }
  )
}

resource "aws_route_table_association" "public" {
  count          = var.public_subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# 3. Dynamic Blocks Demonstration: Security Group Ingress and Egress
resource "aws_security_group" "app_sg" {
  name_prefix = "${local.name_prefix}-app-sg-"
  description = "Security group dynamically configured via Terraform dynamic blocks"
  vpc_id      = aws_vpc.main.id

  # Dynamic Ingress Rules generated from list of objects
  dynamic "ingress" {
    for_each = var.ingress_rules
    iterator = rule
    content {
      description = rule.value.description
      from_port   = rule.value.port
      to_port     = rule.value.port
      protocol    = rule.value.protocol
      cidr_blocks = rule.value.cidr_blocks
    }
  }

  # Dynamic Egress Rules
  dynamic "egress" {
    for_each = var.egress_rules
    iterator = rule
    content {
      description = rule.value.description
      from_port   = rule.value.from_port
      to_port     = rule.value.to_port
      protocol    = rule.value.protocol
      cidr_blocks = rule.value.cidr_blocks
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.common_tags,
    {
      Name        = "${local.name_prefix}-app-sg"
      PatternType = "dynamic_block"
    }
  )
}

# 4. Amazon Linux 2023 AMI Lookup
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 5. EC2 Instances with Conditional Sizing, Count, and Monitoring
resource "aws_instance" "app" {
  count                       = local.instance_count
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = local.instance_type
  subnet_id                   = aws_subnet.public[count.index % var.public_subnet_count].id
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = true
  monitoring                  = local.enable_monitoring

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello from ${var.environment} App Instance ${count.index + 1}" > /var/www/html/index.html
              EOF

  tags = merge(
    local.common_tags,
    {
      Name        = "${local.name_prefix}-app-node-${count.index + 1}"
      Role        = "Application-Server"
      NodeIndex   = tostring(count.index + 1)
      Environment = var.environment
    }
  )
}

# 6. Conditional Resource Creation: Bastion Host
resource "aws_instance" "bastion" {
  count                  = var.enable_bastion ? 1 : 0
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-bastion"
      Role = "Bastion-Host"
    }
  )
}
