# Day 10 Hands-on Tasks — Dynamic Blocks, Conditionals, and Splat Expressions

## Overview
In this lab, you will practice using conditional ternary expressions, dynamic blocks with custom iterators, and splat expressions (`[*]`) to manage multi-AZ VPC infrastructure and EC2 workloads dynamically.

---

## Tasks & Exercises

### Task 1: Initialize and Validate the Project
1. Open a terminal and navigate to the Day 10 directory:
   ```bash
   cd Day_10
   ```
2. Initialize the working directory to download the AWS provider:
   ```bash
   terraform init
   ```
3. Format and validate the configuration files:
   ```bash
   terraform fmt
   terraform validate
   ```

---

### Task 2: Evaluate Conditional Expressions in Dev Mode
1. Review the `terraform.tfvars` file (configured with `environment = "dev"`).
2. Generate an execution plan:
   ```bash
   terraform plan
   ```
3. Verify that:
   - Only 1 application node is planned (`local.instance_count` evaluated to 1).
   - Instance type is `t3.micro`.
   - Detailed monitoring is `false`.
   - Bastion host is not created (`enable_bastion = false`).

---

### Task 3: Provision Dev Infrastructure
1. Apply the configuration:
   ```bash
   terraform apply -auto-approve
   ```
2. Examine the generated outputs:
   - Notice how `public_subnet_ids` extracted all subnet IDs via `aws_subnet.public[*].id`.
   - Notice how `app_instance_private_ips` extracted IPs via `aws_instance.app[*].private_ip`.
   - Observe `bastion_host_info` reporting `status = "disabled"`.

---

### Task 4: Test Dynamic Ingress Rule Modifications
1. Open `terraform.tfvars` and add a new port to `ingress_rules` (e.g. port `9090` for metrics):
   ```hcl
   {
     port        = 9090
     protocol    = "tcp"
     description = "Prometheus metrics"
     cidr_blocks = ["10.0.0.0/16"]
   }
   ```
2. Run `terraform plan`:
   - Verify that Terraform only updates the security group rules dynamically without recreating the whole security group or instances.
3. Revert the change or apply as desired.

---

### Task 5: Switch to Production Mode (Ternary & Feature Flag Test)
1. In `terraform.tfvars`, change `environment = "prod"` and `enable_bastion = true`.
2. Run `terraform plan`:
   - Instance count scales from 1 to 3.
   - Instance type scales from `t3.micro` to `t3.medium`.
   - Detailed CloudWatch monitoring is enabled.
   - Bastion host EC2 instance is planned for creation.
3. Run `terraform apply -auto-approve` (or review plan).

---

### Task 6: Teardown & Clean State
1. When done with practical testing, destroy all AWS resources to eliminate ongoing costs:
   ```bash
   terraform destroy -auto-approve
   ```
2. Verify with `terraform state list` that no resources remain.
