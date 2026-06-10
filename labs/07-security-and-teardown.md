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

## Full Teardown Order

Use this when you are completely finished with the lab and do not need the Neptune graph, notebook, S3 data, or optional Ontop endpoint anymore.

Delete resources in this order:

```text
1. Optional Ontop EC2 lab
2. Neptune Workbench / SageMaker notebook
3. Neptune DB cluster and DB instance
4. Neptune manual snapshots, if not needed
5. S3 bucket objects and bucket
6. S3 Gateway VPC endpoint
7. IAM loader role and policies
8. Lab security groups
9. Cost check
```

Keep your AWS Budget alert unless you have a reason to remove it.

### 1. Optional Ontop EC2 Lab

If you created the Ontop EC2 instance from Lab 08A, clean it up first.

On the EC2 instance, if you want to remove Docker containers and volumes before terminating:

```bash
cd ~/ontop-lab
docker compose down -v
```

Then terminate the instance:

```text
EC2 -> Instances -> kg-lab-ontop -> Instance state -> Terminate instance
```

Delete the Ontop security group later, after the instance is gone.

### 2. Delete Neptune Workbench / SageMaker Notebook

Stop the notebook first if it is running:

```bash
aws sagemaker stop-notebook-instance \
  --notebook-instance-name aws-neptune-kg-lab-notebook \
  --region us-east-1
```

Wait until it is stopped:

```bash
aws sagemaker describe-notebook-instance \
  --notebook-instance-name aws-neptune-kg-lab-notebook \
  --region us-east-1 \
  --query 'NotebookInstanceStatus' \
  --output text
```

Then delete it:

```bash
aws sagemaker delete-notebook-instance \
  --notebook-instance-name aws-neptune-kg-lab-notebook \
  --region us-east-1
```

Console path:

```text
SageMaker AI -> Notebook instances -> aws-neptune-kg-lab-notebook -> Actions -> Stop
SageMaker AI -> Notebook instances -> aws-neptune-kg-lab-notebook -> Actions -> Delete
```

### 3. Delete Neptune DB Instance And Cluster

If the Neptune cluster is stopped, start it first. Neptune administrative actions are limited while stopped.

```bash
aws neptune start-db-cluster \
  --db-cluster-identifier kg-lab-neptune \
  --region us-east-1
```

Wait until available:

```bash
aws neptune describe-db-clusters \
  --db-cluster-identifier kg-lab-neptune \
  --region us-east-1 \
  --query 'DBClusters[0].Status' \
  --output text
```

Delete the DB instance:

```bash
aws neptune delete-db-instance \
  --db-instance-identifier kg-lab-neptune-instance-1 \
  --skip-final-snapshot \
  --region us-east-1
```

Wait until the instance is deleted. Then delete the cluster:

```bash
aws neptune delete-db-cluster \
  --db-cluster-identifier kg-lab-neptune \
  --skip-final-snapshot \
  --region us-east-1
```

Console path:

```text
Neptune -> Databases
Select kg-lab-neptune-instance-1
Actions -> Delete
Create final snapshot: No, for disposable lab data

Then confirm the cluster is gone.
```

If you want a recoverable copy, create a final snapshot instead of skipping it. For disposable labs, skipping the final snapshot avoids ongoing manual snapshot storage cost.

### 4. Delete Neptune Snapshots

Check for manual snapshots:

```text
Neptune -> Snapshots
```

Delete lab snapshots you do not need.

CLI discovery:

```bash
aws neptune describe-db-cluster-snapshots \
  --region us-east-1 \
  --query 'DBClusterSnapshots[?contains(DBClusterIdentifier, `kg-lab-neptune`)].{Snapshot:DBClusterSnapshotIdentifier,Status:Status}' \
  --output table
```

Delete a snapshot only if you are sure it is from this lab:

```bash
aws neptune delete-db-cluster-snapshot \
  --db-cluster-snapshot-identifier <snapshot-id> \
  --region us-east-1
```

### 5. Empty And Delete The S3 Bucket

For the lab bucket:

```bash
aws s3 rm s3://kg-lab-neptune-data-<unique-suffix> --recursive

aws s3api delete-bucket \
  --bucket kg-lab-neptune-data-<unique-suffix> \
  --region us-east-1
```

Only run recursive delete against the lab bucket.

### 6. Delete The S3 Gateway VPC Endpoint

Find the endpoint:

```bash
aws ec2 describe-vpc-endpoints \
  --region us-east-1 \
  --filters "Name=service-name,Values=com.amazonaws.us-east-1.s3" \
  --query 'VpcEndpoints[].{Endpoint:VpcEndpointId,Vpc:VpcId,State:State,Service:ServiceName}' \
  --output table
```

Delete only the endpoint you created for the lab, such as `kg-lab-s3-gateway-endpoint`:

```bash
aws ec2 delete-vpc-endpoints \
  --vpc-endpoint-ids <vpce-id> \
  --region us-east-1
```

If the endpoint existed before the lab or is shared, do not delete it.

### 7. Delete The Neptune Loader IAM Role

If you attached the AWS-managed S3 read-only policy:

```bash
aws iam detach-role-policy \
  --role-name kg-lab-neptune-load-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
```

If you created inline policies, list and delete them:

```bash
aws iam list-role-policies \
  --role-name kg-lab-neptune-load-role

aws iam delete-role-policy \
  --role-name kg-lab-neptune-load-role \
  --policy-name <inline-policy-name>
```

Then delete the role:

```bash
aws iam delete-role \
  --role-name kg-lab-neptune-load-role
```

Do not delete organization-managed, shared, or non-lab IAM roles.

### 8. Delete Lab Security Groups

Delete security groups only after dependent resources are gone.

Lab security groups may include:

```text
kg-lab-neptune-sg
kg-lab-ontop-sg
```

Find them:

```bash
aws ec2 describe-security-groups \
  --region us-east-1 \
  --filters "Name=group-name,Values=kg-lab*" \
  --query 'SecurityGroups[].{GroupName:GroupName,GroupId:GroupId,VpcId:VpcId}' \
  --output table
```

Delete lab-only groups:

```bash
aws ec2 delete-security-group \
  --group-id <sg-id> \
  --region us-east-1
```

Do not delete the default security group or shared security groups.

### 9. Verify Cleanup

Run checks:

```bash
aws neptune describe-db-clusters \
  --region us-east-1 \
  --query 'DBClusters[?contains(DBClusterIdentifier, `kg-lab`)].DBClusterIdentifier' \
  --output table

aws sagemaker list-notebook-instances \
  --region us-east-1 \
  --query 'NotebookInstances[?contains(NotebookInstanceName, `kg-lab`) || contains(NotebookInstanceName, `neptune`)].{Name:NotebookInstanceName,Status:NotebookInstanceStatus}' \
  --output table

aws s3api list-buckets \
  --query 'Buckets[?contains(Name, `kg-lab-neptune-data`)].Name' \
  --output table
```

Then check:

```text
Billing and Cost Management -> Cost Explorer
Billing and Cost Management -> Budgets
```

## Full Teardown Completion Check

You are done when:

- Ontop EC2 instance is terminated, if created.
- Neptune Workbench / SageMaker notebook is deleted.
- Neptune DB instance and cluster are deleted.
- Unneeded manual snapshots are deleted.
- Lab S3 bucket is empty and deleted.
- Lab S3 Gateway VPC endpoint is deleted if it was created only for this lab.
- Lab IAM loader role is deleted.
- Lab-only security groups are deleted.
- Cost Explorer does not show unexpected running lab resources.

## Completion Check

You are done when:

- Workbench is stopped or deleted.
- Neptune cluster is deleted if no longer needed.
- Lab snapshots are reviewed.
- Lab S3 bucket is deleted if no longer needed.
- Lab IAM roles are removed if no longer needed.
- AWS Budgets shows no unexpected spend.
