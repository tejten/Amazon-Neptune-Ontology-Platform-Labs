# Lab 00: AWS CLI Baseline

## Goal

Confirm that your terminal is using the AWS profile, region, and identity you expect before creating any cloud resources.

## Why This Matters

AWS CLI configuration can come from multiple places: environment variables, named profiles, shared credentials files, and default region settings. Before creating Neptune resources, make sure the CLI points to the intended AWS account and region.

## Prerequisites

- AWS CLI installed.
- AWS credentials configured.
- Access to an AWS account where you are allowed to create lab resources.

## Step 1: Check The Active CLI Configuration

Run:

```bash
aws configure list
```

Look for:

```text
profile
access_key
region
```

Example shape:

```text
NAME       : VALUE              : TYPE : LOCATION
profile    : <your-profile>     : env  : ['AWS_PROFILE', 'AWS_DEFAULT_PROFILE']
region     : us-east-1          : env  : ['AWS_REGION', 'AWS_DEFAULT_REGION']
```

If the profile or region is wrong, set them for the current terminal session:

```bash
export AWS_PROFILE=<your-profile>
export AWS_REGION=us-east-1
export AWS_DEFAULT_REGION=us-east-1
```

## Step 2: List Available Profiles

Run:

```bash
aws configure list-profiles
```

Confirm that the expected profile appears in the list.

## Step 3: Confirm The AWS Identity

Run:

```bash
aws sts get-caller-identity
```

Expected shape:

```json
{
  "UserId": "...",
  "Account": "<your-account-id>",
  "Arn": "arn:aws:iam::<your-account-id>:user/<your-user>"
}
```

For a compact identity check:

```bash
aws sts get-caller-identity --query 'Arn' --output text
```

## Step 4: Confirm Region

Run:

```bash
aws configure get region
aws configure get region --profile <your-profile>
```

For these labs, use:

```text
us-east-1
```

## Step 5: Confirm You Can Call Neptune APIs

Run:

```bash
aws neptune describe-db-clusters --region us-east-1
```

If you have no Neptune clusters yet, an empty result is fine.

If you get an access error, you need permissions for Neptune before continuing.

## Step 6: Record Your Lab Context

Do not commit sensitive credentials. You may record non-secret context like this:

```text
Lab profile: <your-profile>
Lab region: us-east-1
Lab account: <your-account-id>
Lab user or role: <your-user-or-role>
```

## Completion Check

You are done when:

- `aws configure list` shows the expected profile.
- `aws sts get-caller-identity` returns the expected account.
- Region is `us-east-1`.
- `aws neptune describe-db-clusters` runs successfully.

