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
Cluster name: kg-lab-neptune
Engine: Amazon Neptune
Environment/workload: Development or test
Capacity: Serverless, if available
Minimum capacity: 1 NCU
Maximum capacity: 2 or 4 NCUs
```

If serverless is not available in your console flow, choose the smallest supported provisioned instance that fits your region and account.

## Step 3: Configure Networking

For a beginner lab, the default VPC is acceptable.

Use:

```text
VPC: default VPC or console-created VPC
Subnet group: default or console-created
Public access: disabled
Port: 8182
Security group: create new
Security group name: kg-lab-neptune-sg
```

Do not expose Neptune publicly.

## Step 4: Configure Security And Durability

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

## Step 5: Create The Cluster

1. Review the settings.
2. Choose **Create database**.
3. Wait until the cluster status is **Available**.

This can take several minutes.

## Step 6: Record Non-Secret Cluster Details

From the cluster details page, record:

```text
Cluster identifier: kg-lab-neptune
Cluster endpoint: <cluster-endpoint>
Reader endpoint: <reader-endpoint>
Port: 8182
Region: us-east-1
```

Do not commit temporary credentials or secrets.

## Step 7: Verify With AWS CLI

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
- IAM database authentication is disabled for the first connection lab.
- Public access is disabled.

## Troubleshooting

If the cluster does not create:

- Confirm your AWS account has Neptune permissions.
- Confirm you are in `us-east-1`.
- Try serverless first, then a small provisioned instance if needed.
- Check whether your account has service quota restrictions.

