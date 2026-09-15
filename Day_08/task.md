# Day 08 Hands-on Tasks: Terraform Meta-Arguments

This guide outlines practical tasks to practice and master Terraform meta-arguments (`count`, `for_each`, `depends_on`, `lifecycle`, and `provider`).

---

## Task 1: Initialize and Format Configuration

1. Open your terminal and navigate to the Day 08 directory:
   ```bash
   cd Day_08
   ```
2. Initialize the Terraform providers:
   ```bash
   terraform init
   ```
3. Run formatting and syntax validation:
   ```bash
   terraform fmt
   terraform validate
   ```

---

## Task 2: Inspect Resource Plan for `count` vs `for_each`

1. Run an execution plan:
   ```bash
   terraform plan
   ```
2. Identify how Terraform addresses `count` resources vs `for_each` resources:
   - `aws_s3_bucket.count_buckets[0]`
   - `aws_s3_bucket.count_buckets[1]`
   - `aws_s3_bucket.count_buckets[2]`
   - `aws_s3_bucket.for_each_buckets["app-assets"]`
   - `aws_s3_bucket.for_each_buckets["raw-data"]`
   - `aws_s3_bucket.for_each_buckets["archive"]`
   - `aws_iam_user.team_members["alice-devops"]`
3. Notice how `for_each` attaches a deterministic string key whereas `count` uses array indexing.

---

## Task 3: Test Resource Lifecycle Behavior

1. Check the `lifecycle` configuration inside `main.tf` for `aws_s3_bucket.lifecycle_demo_bucket`:
   - `create_before_destroy = true`
   - `ignore_changes = [tags["LastModifiedBy"], tags["ExternalTool"]]`
2. Test out-of-band tag changes in AWS or simulate them in configuration to see that Terraform does not attempt to revert ignored attributes.

---

## Task 4: Verify Multi-Region Resource Placement (`provider` meta-argument)

1. Review the secondary disaster recovery bucket `aws_s3_bucket.dr_secondary_bucket` configured with `provider = aws.west`.
2. Notice in the plan output that the bucket region is explicitly set to `us-west-2` while all primary buckets reside in `us-east-1`.

---

## Task 5: Execute Deployment and Inspect Outputs

1. Apply the configuration:
   ```bash
   terraform apply
   ```
2. Query output values and observe splat and map transformations:
   ```bash
   terraform output count_bucket_names
   terraform output for_each_bucket_map
   terraform output versioned_tiers_list
   terraform output iam_user_arns
   ```

---

## Task 6: Explore Deletion Drift (Count vs For_Each)

1. Remove the first element (`"logs"`) from `var.count_bucket_names` in `terraform.tfvars`.
2. Run `terraform plan` and notice how `count` shifts indices, causing destructive recreation of buckets `[1]` and `[2]`.
3. Revert your change back to original.
4. Now remove `"raw-data"` from `var.for_each_storage_tiers`.
5. Run `terraform plan` and observe that ONLY `aws_s3_bucket.for_each_buckets["raw-data"]` is marked for destruction; all other buckets remain completely unaffected.

---

## Task 7: Resource Cleanup

When you have completed all tasks and verification, tear down all provisioned resources:
```bash
terraform destroy -auto-approve
```
