# Lab 01: Cost And Account Safety

## Goal

Set up basic AWS account guardrails before provisioning Neptune.

## Why This Matters

Amazon Neptune, Neptune Workbench, S3, snapshots, and supporting services can incur charges. A small lab environment is manageable, but you should create budget alerts and understand cleanup before you build anything.

## Step 1: Create An AWS Budget

Use the AWS Management Console:

1. Open **Billing and Cost Management**.
2. Choose **Budgets**.
3. Choose **Create budget**.
4. Select a monthly cost budget.
5. Set a threshold such as `$25` or `$50`.
6. Add your email address for alerts.
7. Review and create the budget.

## Step 2: Pick One Region

Use one region for all labs:

```text
us-east-1
```

This keeps networking, S3, IAM roles, and Neptune resources easier to reason about.

## Step 3: Define A Naming Convention

Use predictable names:

```text
Neptune cluster: kg-lab-neptune
Workbench notebook: kg-lab-notebook
Security group: kg-lab-neptune-sg
S3 bucket: kg-lab-neptune-data-<unique-suffix>
IAM role: kg-lab-neptune-load-role
```

S3 bucket names must be globally unique, so include your initials or another unique suffix.

## Step 4: Define Tags

Apply tags to resources when the console allows it:

```text
Project = neptune-ontology-lab
Environment = lab
Owner = <your-name>
```

Tags help you find and clean up resources later.

## Step 5: Lab Safety Defaults

For this non-production lab:

```text
Encryption: enabled
Public access: disabled
Backup retention: 1 day
Deletion protection: disabled only for temporary lab resources
IAM database authentication: disabled for first connection lab
```

IAM database authentication is useful, but it requires SigV4-signed requests. Leave it off until the security lab so you can learn basic SPARQL first.

## Step 6: Cleanup Checklist

When you are done for the day, review:

- Neptune Workbench notebook.
- Neptune DB cluster.
- Neptune cluster snapshots.
- S3 bucket objects.
- IAM roles created for the lab.
- CloudWatch logs.
- Any EC2 or notebook resources.

## Completion Check

You are done when:

- A budget alert exists.
- You have chosen `us-east-1`.
- You have a naming and tagging convention.
- You know which resources must be deleted during cleanup.

