# Lab 07: Security Baseline And Teardown

## Goal

Understand the baseline security model for a Neptune lab and clean up resources safely.

## Security Concepts

Neptune security involves several layers:

```text
AWS account identity
  -> IAM permissions
    -> VPC and security groups
      -> Neptune cluster settings
        -> encryption and logs
          -> IAM database authentication, when enabled
```

## Baseline Controls

For a non-production lab:

- Use one AWS account and one AWS region.
- Keep Neptune private inside a VPC.
- Do not allow public access.
- Restrict security groups to trusted clients such as Neptune Workbench.
- Enable encryption.
- Use short backup retention for temporary labs.
- Tag every resource.
- Avoid committing account IDs, access keys, secrets, endpoints, or internal hostnames to public repositories.

## IAM Database Authentication

IAM database authentication is an optional Neptune setting. When enabled, requests to Neptune must be signed with AWS Signature Version 4.

For early labs, it is easier to leave IAM database authentication disabled.

For later security labs, enable it and test signed access through supported clients.

## Step 1: Review Cluster Settings

In the Neptune console, inspect:

```text
Cluster identifier
VPC
Subnets
Security groups
Encryption
IAM database authentication
Backup retention
Deletion protection
Associated IAM roles
```

## Step 2: Review Security Groups

Open the security group attached to Neptune.

Confirm:

- Inbound access is not open to the public internet.
- Port `8182` is only reachable by expected resources.
- The notebook or client environment can reach Neptune.

## Step 3: Review IAM Roles

Check:

- The Neptune load role only reads the lab S3 bucket.
- The notebook role has only the permissions it needs.
- No long-term secrets are stored in notebooks.

## Step 4: Stop Or Delete Workbench

If you are done for the day, stop or delete the Neptune Workbench notebook to avoid unnecessary cost.

Console path:

```text
Amazon Neptune -> Notebooks -> select notebook -> stop or delete
```

## Step 5: Delete Neptune Cluster

Only do this when you are done with the lab data.

Console path:

```text
Amazon Neptune -> Databases -> select cluster -> delete
```

When prompted:

- Decide whether to keep a final snapshot.
- For temporary labs, deleting without a final snapshot may be acceptable.
- Confirm deletion.

## Step 6: Delete Leftover Snapshots

Check:

```text
Amazon Neptune -> Snapshots
```

Delete lab snapshots you no longer need.

## Step 7: Empty And Delete S3 Bucket

For the lab bucket:

```bash
aws s3 rm s3://kg-lab-neptune-data-<unique-suffix> --recursive
aws s3api delete-bucket --bucket kg-lab-neptune-data-<unique-suffix> --region us-east-1
```

Be careful with `aws s3 rm --recursive`. Only run it against the lab bucket.

## Step 8: Delete Lab IAM Roles

Delete roles you created only for the lab, such as:

```text
kg-lab-neptune-load-role
```

Do not delete shared or organization-managed roles.

## Completion Check

You are done when:

- Workbench is stopped or deleted.
- Neptune cluster is deleted if no longer needed.
- Lab snapshots are reviewed.
- Lab S3 bucket is deleted if no longer needed.
- Lab IAM roles are removed if no longer needed.
- AWS Budgets shows no unexpected spend.

