# Lab 07: Security Baseline And Teardown

## Goal

Understand the baseline security model for a Neptune lab and clean up resources safely.

## Quick Pause Checklist

Use this when you want to continue the lab later without deleting your work.

Stop these resources:

```text
1. Neptune Workbench notebook / SageMaker notebook instance
2. Neptune DB cluster
```

Do not delete these if you want to continue tomorrow:

```text
Neptune cluster
S3 bucket
IAM roles
Security groups
Snapshots
```

Stopping the Neptune cluster keeps the cluster metadata and endpoints, but stops the DB instances. While the cluster is stopped, AWS still charges for cluster storage, manual snapshots, and automated backup storage within the retention window. Neptune may automatically start a stopped cluster after seven days so it can receive maintenance.

### Pause With The Console

Stop the notebook:

```text
Amazon Neptune -> Notebooks
Select aws-neptune-kg-lab-notebook
Actions -> Stop
```

You can also stop it from:

```text
SageMaker AI -> Notebook instances
Select aws-neptune-kg-lab-notebook
Actions -> Stop
```

Stop the Neptune cluster:

```text
Amazon Neptune -> Databases
Select kg-lab-neptune
Actions -> Stop
```

Wait for:

```text
Notebook status: Stopped
Neptune cluster status: Stopped
```

### Pause With The CLI

```bash
aws sagemaker stop-notebook-instance \
  --notebook-instance-name aws-neptune-kg-lab-notebook \
  --region us-east-1

aws neptune stop-db-cluster \
  --db-cluster-identifier kg-lab-neptune \
  --region us-east-1
```

Check status:

```bash
aws sagemaker describe-notebook-instance \
  --notebook-instance-name aws-neptune-kg-lab-notebook \
  --region us-east-1 \
  --query 'NotebookInstanceStatus' \
  --output text

aws neptune describe-db-clusters \
  --db-cluster-identifier kg-lab-neptune \
  --region us-east-1 \
  --query 'DBClusters[0].Status' \
  --output text
```

### Resume Tomorrow

Start the Neptune cluster first:

```text
Amazon Neptune -> Databases
Select kg-lab-neptune
Actions -> Start
```

Then start the notebook:

```text
Amazon Neptune -> Notebooks
Select aws-neptune-kg-lab-notebook
Actions -> Start
```

Wait until both are available, then open JupyterLab and run:

```text
%status
```

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
