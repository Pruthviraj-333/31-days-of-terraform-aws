# Day 09 Hands-on Tasks: Terraform Lifecycle Meta-arguments

This guide provides step-by-step practical exercises to experiment with, test, and observe each of the 6 Terraform lifecycle meta-arguments (`create_before_destroy`, `prevent_destroy`, `ignore_changes`, `replace_triggered_by`, `precondition`, and `postcondition`).

---

## Task 1: Initialization & Validation

1. Navigate to the `Day_09` directory:
   ```bash
   cd Day_09
   ```
2. Initialize Terraform providers:
   ```bash
   terraform init
   ```
3. Format and validate syntax:
   ```bash
   terraform fmt
   terraform validate
   ```

---

## Task 2: Test `precondition` Validation Failure

1. Open `terraform.tfvars` and temporarily change `aws_region` to an unauthorized region:
   ```hcl
   aws_region = "ap-southeast-1"
   ```
2. Run `terraform plan` and observe the custom precondition failure error:
   ```text
   Precondition Failed: Deployment region 'ap-southeast-1' is not in approved list: [us-east-1, us-east-2, us-west-2, eu-west-1].
   ```
3. Revert `aws_region` back to `"us-east-1"`.

---

## Task 3: Test `postcondition` Compliance Validation

1. Open `locals.tf` and temporarily remove the `Compliance` tag from `compliance_tags`.
2. Run `terraform plan` to observe the plan behavior or error warning.
3. Revert `locals.tf` to restore the required `Compliance` tag.

---

## Task 4: Execute Initial Deployment

1. Run the plan and apply:
   ```bash
   terraform plan
   terraform apply -auto-approve
   ```
2. View the resulting outputs:
   ```bash
   terraform output
   ```

---

## Task 5: Test `replace_triggered_by` Behavior

1. Open `terraform.tfvars` and update `app_version`:
   ```hcl
   app_version = "2.0.0"
   ```
2. Run `terraform plan`:
   - Notice that `aws_s3_bucket.version_triggered_storage` is marked for replacement (`-/+`) solely because `terraform_data.app_release.output` changed, even though no bucket parameters were modified directly.
3. Revert or apply as desired.

---

## Task 6: Test `prevent_destroy` Safety Mechanism

1. In `main.tf`, change `prevent_destroy` to `true` inside `aws_s3_bucket.critical_vault`:
   ```hcl
   lifecycle {
     prevent_destroy = true
   }
   ```
2. Run `terraform plan -destroy` or `terraform destroy`:
   - Observe that Terraform immediately errors out, refusing to generate a destruction plan for the protected resource.
3. Set `prevent_destroy` back to `false` when ready to clean up.

---

## Task 7: Resource Teardown

1. Ensure `prevent_destroy = false` in `main.tf`.
2. Tear down all deployed AWS resources:
   ```bash
   terraform destroy -auto-approve
   ```
