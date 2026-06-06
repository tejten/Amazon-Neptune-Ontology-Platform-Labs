# Lab 02: Create A Neptune Database Cluster

## Goal

Create a small non-production Amazon Neptune Database cluster for RDF and SPARQL labs.

## Architecture

```text
AWS account
  -> us-east-1
    -> VPC
      -> Neptune Database cluster
        -> Neptune endpoint on port 8182
```

Neptune is normally deployed inside a VPC. You usually do not connect directly from your laptop unless you set up a tunnel, VPN, or other private network path. For early labs, use Neptune Workbench.

## Step 1: Open The Neptune Console

1. Sign in to the AWS Management Console.
2. Confirm the selected region is `us-east-1`.
3. Search for **Neptune**.
4. Open **Amazon Neptune**.
5. Choose **Databases**.
6. Choose **Create database** or **Create cluster**.

Choose **Neptune Database**, not Neptune Analytics.

## Step 2: Choose Cluster Settings

Use these lab settings when the console asks:

```text
Type: Serverless
Cluster name: kg-lab-neptune
DB instance name: kg-lab-neptune-instance-1
Engine: Amazon Neptune
Engine version: use the latest default shown by the console
Environment/workload: Development or test
Template: Development and testing
Minimum capacity: 1 NCU
Maximum capacity: 16 NCUs
```

If serverless is not available in your console flow, choose the smallest supported provisioned instance that fits your region and account.

Important: the console may default the maximum capacity to `128` NCUs. If the console says the maximum must be between `16` and `128`, change the maximum to `16` NCUs for this lab.

Neptune Serverless charges based on the capacity the database actually uses, but the maximum value is still a cost-risk ceiling. For a beginner lab, use the lowest maximum value the console accepts.

## Step 3: Choose Storage And Availability

Use:

```text
Storage configuration: Neptune Standard
Multi-AZ deployment: No
```

For this beginner lab, do not choose Neptune I/O-Optimized. I/O-Optimized is intended for workloads where predictable I/O pricing or heavier I/O behavior matters. Neptune Standard is the simpler lab choice.

## Step 4: Configure Networking

For a beginner lab, the default VPC is acceptable.

Use:

```text
VPC: default VPC or console-created VPC
Subnet group: default or console-created
Publicly accessible: No
Port: 8182
VPC security groups: create new, preferred
Security group name: kg-lab-neptune-sg
```

Do not expose Neptune publicly.

If the console has already selected unrelated security groups, remove them. For example, do not attach a security group that was created for an unrelated EC2 image, desktop, or marketplace server.

Acceptable beginner options:

```text
Preferred: create new security group named kg-lab-neptune-sg
Simplest fallback: use only the default security group
Avoid: default security group plus unrelated security groups
```

## Step 5: Configure Notebook Creation

The Neptune console can create a notebook during database creation. Turn this on for the first lab.

Use:

```text
Create notebook: On
Notebook instance type: ml.t3.medium
Notebook name: kg-lab-notebook
IAM role: Create an IAM role
IAM role name or suffix: kg-lab-notebook-role
Internet access: Direct access through Amazon SageMaker
```

Some console screens display fixed prefixes. If you see a prefix such as `aws-neptune-` before the notebook name field, enter only:

```text
kg-lab-notebook
```

The final notebook name may appear as:

```text
aws-neptune-kg-lab-notebook
```

Similarly, if the IAM role field shows a prefix such as `AWSNeptuneNotebookRole-`, enter only the suffix:

```text
kg-lab-notebook-role
```

## Step 6: Configure Security And Durability

Use:

```text
Encryption: enabled
IAM database authentication: disabled for now
Backup retention: 1 day
Deletion protection: disabled for temporary lab resources
Tags:
  Project = neptune-ontology-lab
  Environment = lab
  Owner = <your-name>
```

IAM database authentication will be enabled later in the security lab.

If the console shows **Turn on IAM Authentication** selected by default, change it to:

```text
Turn off IAM Authentication
```

The first SPARQL lab is intentionally unauthenticated at the Neptune database layer so Neptune Workbench can connect without SigV4 signing complexity.

## Step 7: Final Pre-Create Checklist

Before choosing **Create database**, confirm:

```text
Type: Serverless
Template: Development and testing
DB cluster name: kg-lab-neptune
DB instance name: kg-lab-neptune-instance-1
Storage: Neptune Standard
Minimum NCUs: 1
Maximum NCUs: 16
Multi-AZ deployment: No
Publicly accessible: No
Security groups: only lab-appropriate security group selections
Create notebook: On
Notebook instance type: ml.t3.medium
Notebook name: kg-lab-notebook
IAM DB authentication: Off
Encryption: enabled
```

## Step 8: Create The Cluster

1. Review the settings.
2. Choose **Create database**.
3. Wait until the cluster status is **Available**.

This can take several minutes.

## Step 9: Record Non-Secret Cluster Details

From the cluster details page, record:

```text
Cluster identifier: kg-lab-neptune
Cluster endpoint: <cluster-endpoint>
Reader endpoint: <reader-endpoint>
Port: 8182
Region: us-east-1
```

Do not commit temporary credentials or secrets.

## Step 10: Verify With AWS CLI

Run:

```bash
aws neptune describe-db-clusters \
  --db-cluster-identifier kg-lab-neptune \
  --region us-east-1
```

For a compact output:

```bash
aws neptune describe-db-clusters \
  --db-cluster-identifier kg-lab-neptune \
  --region us-east-1 \
  --query 'DBClusters[0].{Cluster:DBClusterIdentifier,Status:Status,Endpoint:Endpoint,Port:Port,IAMAuth:IAMDatabaseAuthenticationEnabled}' \
  --output table
```

## Completion Check

You are done when:

- The Neptune cluster status is `available`.
- The cluster endpoint exists.
- Port is `8182`.
- Maximum serverless capacity is the lowest value the console accepts, currently `16` NCUs in this console flow.
- Neptune Standard storage is selected.
- IAM database authentication is disabled for the first connection lab.
- Public access is disabled.
- The notebook is created or ready to create in the next lab.

## Troubleshooting

If the cluster does not create:

- Confirm your AWS account has Neptune permissions.
- Confirm you are in `us-east-1`.
- Try serverless first, then a small provisioned instance if needed.
- Check whether your account has service quota restrictions.
