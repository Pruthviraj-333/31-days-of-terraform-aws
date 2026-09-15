# Day 08 — Terraform Meta-Arguments: Complete Guide

> **31 Days of Terraform (AWS)** — A hands-on journey to master Terraform and Infrastructure as Code on AWS.

---

## Topics Covered

* [x] **Meta-Arguments Overview** — Special arguments available across all Terraform resource blocks
* [x] **`count` Meta-Argument** — Numeric indexing, index addressing (`[0]`, `[1]`), and element shifting pitfalls
* [x] **`for_each` Meta-Argument** — Map and Set iteration, key-based addressing (`["name"]`), and resource stability
* [x] **`depends_on` Meta-Argument** — Explicit dependency ordering in the Directed Acyclic Graph (DAG)
* [x] **`lifecycle` Meta-Argument** — Customizing resource behaviors (`create_before_destroy`, `prevent_destroy`, `ignore_changes`)
* [x] **`provider` Meta-Argument** — Provider aliasing and multi-region deployments (`aws.west`)
* [x] **Advanced Output Projections** — Splat expressions (`[*]`), list `for` loops, map `for` transformations, and conditional filtering
* [x] **Hands-on AWS Implementation** — S3 multi-tier storage, IAM users, explicit audit log ordering, drift-protected buckets, and cross-region replicas

---

## Architectural Overview

![Terraform Meta-Arguments Architecture](./screenshots/00-terraform-meta-arguments-architecture.png)

---

## 1. Understanding Terraform Meta-Arguments

Meta-arguments are special arguments built into Terraform that can be used with **any resource or module block** to modify how Terraform creates, addresses, and manages the lifecycle of that resource.

Unlike standard resource-specific arguments (e.g., `bucket` for S3, `ami` for EC2), meta-arguments belong to Terraform's core execution engine.

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                          TERRAFORM META-ARGUMENTS                           │
├───────────────┬─────────────────────────────────────────────────────────────┤
│ Meta-Argument │ Primary Purpose                                             │
├───────────────┼─────────────────────────────────────────────────────────────┤
│ count         │ Create multiple resource instances based on a whole number  │
│ for_each      │ Create multiple instances based on a map or set of strings  │
│ depends_on    │ Specify explicit resource creation / destruction order      │
│ lifecycle     │ Override standard create-destroy-update lifecycles          │
│ provider      │ Route a resource to a non-default aliased provider          │
│ provisioner   │ Run custom shell commands/scripts (considered last resort)  │
└───────────────┴─────────────────────────────────────────────────────────────┘
```

---

## 2. The `count` Meta-Argument

The `count` meta-argument accepts a whole number and provisions that exact number of identical (or indexed) resource instances.

### Syntax and Resource Addressing
```hcl
resource "aws_s3_bucket" "count_buckets" {
  count = length(var.count_bucket_names)

  bucket = "${local.name_prefix}-cnt-${var.count_bucket_names[count.index]}-${random_string.suffix.result}"
}
```

Terraform assigns each resource instance a zero-based numeric index:
- `aws_s3_bucket.count_buckets[0]`
- `aws_s3_bucket.count_buckets[1]`
- `aws_s3_bucket.count_buckets[2]`

### The Index Shifting Problem (Why `count` can be dangerous)
When `count` is used over a list (`["logs", "media", "backups"]`), removing `"logs"` shifts the remaining items:
- `"media"` becomes index `0` (formerly `1`)
- `"backups"` becomes index `1` (formerly `2`)

Terraform sees index `0` changing name from `"logs"` to `"media"`, forcing the destruction and recreation of existing storage buckets and potential data loss.

### When to use `count`:
- Toggling a resource conditionally on or off (`count = var.enable_feature ? 1 : 0`)
- Creating truly identical, interchangeable resources (e.g., identical worker nodes)

---

## 3. The `for_each` Meta-Argument

The `for_each` meta-argument accepts a **map** or **set of strings**, creating an instance for each item. Each instance is tracked by its distinct, human-readable key instead of a numeric index.

### 1. `for_each` with a Map
```hcl
resource "aws_s3_bucket" "for_each_buckets" {
  for_each = var.for_each_storage_tiers

  bucket = "${local.name_prefix}-fe-${each.key}-${random_string.suffix.result}"

  tags = {
    TierKey = each.key
    Purpose = each.value.purpose
  }
}
```

Terraform addresses resources deterministically:
- `aws_s3_bucket.for_each_buckets["app-assets"]`
- `aws_s3_bucket.for_each_buckets["raw-data"]`
- `aws_s3_bucket.for_each_buckets["archive"]`

### 2. `for_each` with a Set of Strings
```hcl
resource "aws_iam_user" "team_members" {
  for_each = var.iam_user_names

  name = "${local.name_prefix}-${each.value}"
}
```
Addresses instances by username:
- `aws_iam_user.team_members["alice-devops"]`
- `aws_iam_user.team_members["bob-developer"]`

### Benefits of `for_each`:
- **Deterministic Addressing:** Adding, removing, or reordering elements only modifies the targeted key without affecting neighboring resources.
- **Production Safety:** Recommended for production infrastructure, networking tiers, and databases.

---

## 4. The `depends_on` Meta-Argument

Terraform automatically builds a Directed Acyclic Graph (DAG) by analyzing attribute references (e.g., `vpc_id = aws_vpc.main.id`).

However, when an infrastructure dependency exists outside Terraform's direct attribute references (such as application-level log consumers or IAM role propagation), `depends_on` creates an explicit dependency.

```hcl
resource "aws_s3_bucket" "central_audit_log" {
  bucket = "${local.name_prefix}-audit-log-${random_string.suffix.result}"

  # Explicit dependency: Do not create until primary storage and IAM users exist
  depends_on = [
    aws_s3_bucket.for_each_buckets,
    aws_s3_bucket.count_buckets,
    aws_iam_user.team_members
  ]
}
```

---

## 5. The `lifecycle` Meta-Argument

The `lifecycle` block customizes how Terraform manages resource replacement and drift:

```hcl
resource "aws_s3_bucket" "lifecycle_demo_bucket" {
  bucket = "${local.name_prefix}-lifecycle-${random_string.suffix.result}"

  lifecycle {
    # 1. Zero-downtime updates: create replacement before destroying existing
    create_before_destroy = true

    # 2. Prevent accidental destruction via `terraform destroy`
    # prevent_destroy = true

    # 3. Ignore out-of-band updates (e.g., autoscalers, external tagging tools)
    ignore_changes = [
      tags["LastModifiedBy"],
      tags["ExternalTool"]
    ]
  }
}
```

### Lifecycle Rules Summary:
1. **`create_before_destroy = true`**: Reverses the default replacement workflow (which normally destroys before creating) to avoid downtime.
2. **`prevent_destroy = true`**: Generates a hard plan error if an operation would result in the resource being destroyed.
3. **`ignore_changes = [...]`**: Suppresses drift detection on specific resource arguments updated outside of Terraform.

---

## 6. The `provider` Meta-Argument (Multi-Region / Multi-Account)

The `provider` meta-argument allows assigning a specific resource to a non-default provider alias.

### 1. Provider Definition (`provider.tf`)
```hcl
# Default Provider (us-east-1)
provider "aws" {
  region = "us-east-1"
}

# Aliased Alternate Provider (us-west-2)
provider "aws" {
  alias  = "west"
  region = "us-west-2"
}
```

### 2. Resource Assignment (`main.tf`)
```hcl
resource "aws_s3_bucket" "dr_secondary_bucket" {
  provider = aws.west

  bucket = "${local.name_prefix}-dr-west-${random_string.suffix.result}"
}
```

---

## 7. Advanced Output Transformations (`for` Expressions & Splat)

Terraform outputs support expressive transformations across collections created with `count` and `for_each`:

### 1. Splat Expression (`[*]`)
```hcl
output "count_bucket_names" {
  value = aws_s3_bucket.count_buckets[*].bucket
}
```

### 2. Map `for` Expression
```hcl
output "for_each_bucket_map" {
  value = {
    for tier_key, bucket in aws_s3_bucket.for_each_buckets :
    tier_key => bucket.bucket
  }
}
```

### 3. Filtered List `for` Expression (`if` condition)
```hcl
output "versioned_tiers_list" {
  value = [
    for tier_key, config in var.for_each_storage_tiers :
    tier_key if config.versioning
  ]
}
```

---

## 8. Detailed Comparison: `count` vs `for_each`

| Feature | `count` | `for_each` |
| :--- | :--- | :--- |
| **Accepted Types** | Whole number (`number`) or list length | Map (`map`) or Set (`set(string)`) |
| **Resource Address** | Numeric index: `resource.name[0]` | Key-based: `resource.name["app-assets"]` |
| **Element Deletion** | Shifts all subsequent indices, causing destructive recreation | Removes only the deleted key; leaves other resources unchanged |
| **Item Addition** | Appends or causes re-indexing depending on position | Directly inserts new key instance |
| **Resource Sizing** | Good for uniform identical replicas | Good for heterogeneous tiers with custom configs |
| **Best Practice** | Simple counters & conditional flags (`0` or `1`) | Production resources, networking, storage, IAM |

---

## 9. Complete Configuration Files

### 1. `provider.tf`
```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "west"
  region = var.secondary_region
}
```

### 2. `variables.tf`
```hcl
variable "aws_region" {
  description = "Primary AWS deployment region (Default Provider)"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary AWS deployment region for disaster recovery (Aliased Provider)"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "day08-meta-args"
}

variable "count_bucket_names" {
  description = "List of bucket category names managed using the count meta-argument"
  type        = list(string)
  default     = ["logs", "media", "backups"]
}

variable "for_each_storage_tiers" {
  description = "Map of storage tiers with specific attributes managed using for_each"
  type = map(object({
    purpose        = string
    versioning     = bool
    lifecycle_days = number
  }))
  default = {
    app-assets = {
      purpose        = "Static web and application media assets"
      versioning     = true
      lifecycle_days = 90
    }
    raw-data = {
      purpose        = "Ingested raw telemetry datasets"
      versioning     = false
      lifecycle_days = 30
    }
    archive = {
      purpose        = "Long-term compliance and audit archives"
      versioning     = true
      lifecycle_days = 365
    }
  }
}

variable "iam_user_names" {
  description = "Set of IAM user names to provision with for_each"
  type        = set(string)
  default     = ["alice-devops", "bob-developer", "charlie-qa"]
}

variable "resource_tags" {
  description = "Common baseline tags applied across all resources"
  type        = map(string)
  default = {
    Owner     = "DevOps-Team"
    ManagedBy = "Terraform"
    Project   = "Terraform-Meta-Arguments"
    Day       = "Day_08"
  }
}
```

### 3. `locals.tf`
```hcl
locals {
  name_prefix = "${var.environment}-${var.project_name}"

  common_tags = merge(
    var.resource_tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      CreatedAt   = "Day_08"
    }
  )

  total_storage_tiers = length(var.for_each_storage_tiers)
}
```

### 4. `main.tf`
```hcl
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# 1. count Example
resource "aws_s3_bucket" "count_buckets" {
  count = length(var.count_bucket_names)

  bucket        = "${local.name_prefix}-cnt-${var.count_bucket_names[count.index]}-${random_string.suffix.result}"
  force_destroy = true

  tags = merge(
    local.common_tags,
    {
      Name        = "${local.name_prefix}-cnt-${var.count_bucket_names[count.index]}"
      MetaArg     = "count"
      IndexNumber = tostring(count.index)
    }
  )
}

# 2. for_each (Map) Example
resource "aws_s3_bucket" "for_each_buckets" {
  for_each = var.for_each_storage_tiers

  bucket        = "${local.name_prefix}-fe-${each.key}-${random_string.suffix.result}"
  force_destroy = true

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-fe-${each.key}"
      MetaArg = "for_each_map"
      Purpose = each.value.purpose
    }
  )
}

resource "aws_s3_bucket_versioning" "for_each_versioning" {
  for_each = {
    for key, tier in var.for_each_storage_tiers : key => tier if tier.versioning
  }

  bucket = aws_s3_bucket.for_each_buckets[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

# 2B. for_each (Set) Example
resource "aws_iam_user" "team_members" {
  for_each = var.iam_user_names

  name          = "${local.name_prefix}-${each.value}"
  force_destroy = true

  tags = merge(
    local.common_tags,
    {
      Name     = "${local.name_prefix}-${each.value}"
      MetaArg  = "for_each_set"
      Username = each.value
    }
  )
}

# 3. depends_on Example
resource "aws_s3_bucket" "central_audit_log" {
  bucket        = "${local.name_prefix}-audit-log-${random_string.suffix.result}"
  force_destroy = true

  depends_on = [
    aws_s3_bucket.for_each_buckets,
    aws_s3_bucket.count_buckets,
    aws_iam_user.team_members
  ]

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-audit-log"
      MetaArg = "depends_on"
    }
  )
}

# 4. lifecycle Example
resource "aws_s3_bucket" "lifecycle_demo_bucket" {
  bucket        = "${local.name_prefix}-lifecycle-${random_string.suffix.result}"
  force_destroy = true

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      tags["LastModifiedBy"],
      tags["ExternalTool"]
    ]
  }

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-lifecycle-bucket"
      MetaArg = "lifecycle"
    }
  )
}

# 5. provider Example (Multi-Region)
resource "aws_s3_bucket" "dr_secondary_bucket" {
  provider = aws.west

  bucket        = "${local.name_prefix}-dr-west-${random_string.suffix.result}"
  force_destroy = true

  tags = merge(
    local.common_tags,
    {
      Name         = "${local.name_prefix}-dr-secondary-bucket"
      MetaArg      = "provider_alias"
      TargetRegion = var.secondary_region
    }
  )
}
```

### 5. `outputs.tf`
```hcl
output "count_bucket_names" {
  description = "All bucket names created via count (Splat Expression: [*])"
  value       = aws_s3_bucket.count_buckets[*].bucket
}

output "count_bucket_arns" {
  description = "All bucket ARNs created via count (Splat Expression: [*])"
  value       = aws_s3_bucket.count_buckets[*].arn
}

output "for_each_bucket_map" {
  description = "Map projection of tier key to bucket name"
  value = {
    for tier_key, bucket in aws_s3_bucket.for_each_buckets :
    tier_key => bucket.bucket
  }
}

output "versioned_tiers_list" {
  description = "Filtered list of tier names that have versioning enabled"
  value = [
    for tier_key, config in var.for_each_storage_tiers :
    tier_key if config.versioning
  ]
}

output "iam_user_arns" {
  description = "Map of IAM usernames to their generated AWS ARNs"
  value = {
    for user, resource in aws_iam_user.team_members :
    user => resource.arn
  }
}

output "audit_log_bucket_name" {
  description = "Audit log bucket name (created with explicit depends_on)"
  value       = aws_s3_bucket.central_audit_log.bucket
}

output "dr_secondary_bucket_region" {
  description = "Region of disaster recovery bucket provisioned with aws.west provider"
  value       = aws_s3_bucket.dr_secondary_bucket.region
}
```

---

## 10. Diagrams

### Meta-Arguments Dependency & Execution Flow

```mermaid
flowchart TD
    subgraph Providers ["Provider Configurations"]
        PDefault["Default Provider (us-east-1)"]
        PAlias["Aliased Provider aws.west (us-west-2)"]
    end

    subgraph MetaArgs ["Terraform Meta-Arguments Layer"]
        MCount["count = 3<br>Index Addressing [0, 1, 2]"]
        MForEachMap["for_each = var.tiers<br>Key Addressing ['app-assets']"]
        MForEachSet["for_each = var.users<br>Key Addressing ['alice-devops']"]
        MLifecycle["lifecycle {<br>  create_before_destroy = true<br>  ignore_changes = [tags]<br>}"]
        MDepends["depends_on = [...]<br>Explicit DAG Ordering"]
    end

    subgraph Provisioned ["AWS Provisioned Resources"]
        RCnt["aws_s3_bucket.count_buckets[0..2]"]
        RFE["aws_s3_bucket.for_each_buckets[*]"]
        RIAM["aws_iam_user.team_members[*]"]
        RLife["aws_s3_bucket.lifecycle_demo_bucket"]
        RDep["aws_s3_bucket.central_audit_log"]
        RDR["aws_s3_bucket.dr_secondary_bucket (us-west-2)"]
    end

    PDefault --> MCount --> RCnt
    PDefault --> MForEachMap --> RFE
    PDefault --> MForEachSet --> RIAM
    PDefault --> MLifecycle --> RLife
    PAlias --> RDR

    RCnt --> MDepends
    RFE --> MDepends
    RIAM --> MDepends
    MDepends --> RDep

    style PDefault fill:#1E293B,stroke:#38BDF8,stroke-width:2px,color:#fff
    style PAlias fill:#4B2E83,stroke:#A78BFA,stroke-width:2px,color:#fff
    style MCount fill:#0284C7,stroke:#333,stroke-width:2px,color:#fff
    style MForEachMap fill:#0D9488,stroke:#333,stroke-width:2px,color:#fff
    style MForEachSet fill:#059669,stroke:#333,stroke-width:2px,color:#fff
    style MLifecycle fill:#D97706,stroke:#333,stroke-width:2px,color:#fff
    style MDepends fill:#DC2626,stroke:#333,stroke-width:2px,color:#fff
    style RDep fill:#7C3AED,stroke:#333,stroke-width:2px,color:#fff
```

---

## 11. Verification & Screenshots

The following screenshots capture the execution plan, resource addressing comparisons, deployment lifecycle, and output transformations for Day 08.

### 1. Execution Plan Inspection (`terraform plan`)

Reviewing the planned resource creations and addressing formats across all meta-arguments:

#### IAM User Creation from Set (`for_each` — `alice-devops`)

![Plan IAM User Alice](./screenshots/01-terraform-plan-iam-users-alice.png)

#### IAM User Creation from Set (`for_each` — `bob-developer`)

![Plan IAM User Bob](./screenshots/02-terraform-plan-iam-users-bob.png)

#### IAM User Creation from Set (`for_each` — `charlie-qa`)

![Plan IAM User Charlie](./screenshots/03-terraform-plan-iam-users-charlie.png)

#### Explicit Dependency Storage Bucket (`depends_on`)

![Plan Depends On Audit Log](./screenshots/04-terraform-plan-depends-on-audit-log.png)

#### S3 Bucket Creation via `count` (Index `[0]` — Logs)

![Plan Count Bucket Index 0 Logs](./screenshots/05-terraform-plan-count-bucket-0-logs.png)

#### S3 Bucket Tags & Index Metadata (Index `[0]`)

![Plan Count Bucket Index 0 Tags](./screenshots/06-terraform-plan-count-bucket-0-tags.png)

#### S3 Bucket Creation via `count` (Index `[1]` — Media)

![Plan Count Bucket Index 1 Media](./screenshots/07-terraform-plan-count-bucket-1-media.png)

#### S3 Bucket Creation via `count` (Index `[2]` — Backups)

![Plan Count Bucket Index 2 Backups](./screenshots/08-terraform-plan-count-bucket-2-backups.png)

#### S3 Bucket Tags & Index Metadata (Index `[2]`)

![Plan Count Bucket Index 2 Tags](./screenshots/09-terraform-plan-count-bucket-2-tags.png)

#### Multi-Region S3 Bucket (`provider = aws.west` targeting `us-west-2`)

![Plan Provider Alias DR West](./screenshots/10-terraform-plan-provider-alias-dr-west.png)

#### S3 Bucket Creation via `for_each` Map (`app-assets`)

![Plan For Each App Assets](./screenshots/11-terraform-plan-for-each-app-assets.png)

#### S3 Bucket Tags & Purpose Metadata (`app-assets`)

![Plan For Each App Assets Tags](./screenshots/12-terraform-plan-for-each-app-assets-tags.png)

#### S3 Bucket Creation via `for_each` Map (`archive`)

![Plan For Each Archive](./screenshots/13-terraform-plan-for-each-archive.png)

#### S3 Bucket Creation via `for_each` Map (`raw-data`)

![Plan For Each Raw Data](./screenshots/14-terraform-plan-for-each-raw-data.png)

#### S3 Bucket with Custom `lifecycle` Configuration

![Plan Lifecycle Demo Bucket](./screenshots/15-terraform-plan-lifecycle-demo-bucket.png)

#### S3 Bucket Versioning & Plan Summary (Plan: 15 to add)

![Plan Versioning Suffix Summary](./screenshots/16-terraform-plan-versioning-suffix-summary.png)

#### Output Projections Preview

![Plan Outputs Preview](./screenshots/17-terraform-plan-outputs-preview.png)

---

### 2. Terraform Apply Execution (`terraform apply`)

Executing the deployment plan to provision all 15 resources across multiple regions:

#### Provisioning Lifecycle & Apply Complete Summary (15 Added)

![Terraform Apply Creating and Complete](./screenshots/18-terraform-apply-creating-and-complete.png)

#### Typed Output Projections on Apply Completion

![Terraform Apply Full Outputs](./screenshots/19-terraform-apply-full-outputs.png)

---

### 3. Inspecting Outputs (`terraform output`)

Querying the splat expressions (`[*]`), map transformations (`for`), and filtered list projections:

```bash
terraform output
```

![Terraform Output Command Inspection](./screenshots/20-terraform-output-command-inspection.png)

---

## Key Takeaways

1. **`for_each` over `count`:** Prefer `for_each` for real-world cloud resources because key-based addressing prevents accidental destructive recreation when list elements are removed or reordered.
2. **Use `count` for Boolean Toggles:** Use `count = var.enabled ? 1 : 0` for simple feature switches and conditional resource creation.
3. **Explicit DAG Control:** Use `depends_on` only when Terraform cannot detect dependencies through direct resource attribute references.
4. **Lifecycle Protection:** Use `create_before_destroy = true` for zero-downtime updates and `ignore_changes` to prevent Terraform from fighting external automation tools.
5. **Multi-Region Deployments:** Use provider aliases (`provider = aws.<alias>`) within individual resource blocks to provision across multiple AWS regions simultaneously.

---

## Next Steps

In **Day 09**, we will explore **Advanced State Management**, diving into `terraform state` subcommands (`list`, `show`, `mv`, `rm`), state locking, and state disaster recovery.

