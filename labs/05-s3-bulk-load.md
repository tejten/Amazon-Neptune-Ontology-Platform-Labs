# Lab 05: S3 Bulk Load Into Neptune

## Goal

Load RDF data from Amazon S3 into Neptune using the Neptune bulk loader.

## Why Bulk Load

SPARQL `INSERT DATA` is fine for small examples. For larger RDF files, use the Neptune bulk loader. The loader reads RDF files from S3 and imports them into the cluster.

## Architecture

```text
RDF file
  -> Amazon S3 bucket
    -> IAM role with S3 read access
      -> Neptune bulk loader
        -> Neptune RDF graph
```

## Step 1: Create An S3 Bucket

Use the AWS Console or CLI.

Example CLI:

```bash
aws s3api create-bucket \
  --bucket kg-lab-neptune-data-<unique-suffix> \
  --region us-east-1
```

Enable block public access and encryption in the S3 console.

Create a folder-like prefix:

```bash
aws s3api put-object \
  --bucket kg-lab-neptune-data-<unique-suffix> \
  --key rdf/
```

## Step 2: Create A Turtle File Locally

Create a file named `aircraft-sample.ttl`:

```turtle
@prefix ex: <https://example.com/aero/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

ex:Aircraft_002 a ex:Aircraft ;
  ex:tailNumber "N002KG" ;
  ex:hasSystem ex:Engine_002 .

ex:Engine_002 a ex:AircraftSystem ;
  ex:systemName "Right Engine" ;
  ex:hasPart ex:Part_FuelPump_002 .

ex:Part_FuelPump_002 a ex:Part ;
  ex:partNumber "FP-8842" ;
  ex:serialNumber "SN-FP-10002" .

ex:MaintEvent_1002 a ex:MaintenanceEvent ;
  ex:performedOn ex:Part_FuelPump_002 ;
  ex:eventDate "2026-06-07"^^xsd:date ;
  ex:eventType "Inspection" ;
  ex:outcome "Passed" .
```

## Step 3: Upload The File To S3

```bash
aws s3 cp aircraft-sample.ttl \
  s3://kg-lab-neptune-data-<unique-suffix>/rdf/aircraft-sample.ttl \
  --region us-east-1
```

## Step 4: Create An IAM Role For Neptune Loading

The Neptune loader needs an IAM role that allows Neptune to read from S3.

AWS's Neptune bulk-load walkthrough uses the IAM role wizard with S3 first, then updates the role trust relationship so Neptune can assume the role.

### Step 4A: Create The Role In IAM

In the IAM console:

1. Open **IAM**.
2. Choose **Roles**.
3. Choose **Create role**.
4. Trusted entity type: **AWS service**.
5. Service or use case: **S3**.
6. Use case: **S3**.
7. Choose **Next**.

On the **Add permissions** page, search for:

```text
AmazonS3ReadOnlyAccess
```

Select it for the beginner lab, then choose **Next**.

This AWS-managed policy grants read/list access across S3. That is convenient for the lab, but broader than a production role should be. A production-style role should restrict S3 access to the specific lab bucket and prefix.

Name the role:

```text
kg-lab-neptune-load-role
```

Create the role and open it.

### Step 4B: Edit The Trust Relationship

After the role is created, open:

```text
IAM -> Roles -> kg-lab-neptune-load-role -> Trust relationships -> Edit trust policy
```

Replace the trust policy with:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

Choose **Update policy**.

Why `rds.amazonaws.com`? Neptune uses the Amazon RDS service principal for this role assumption path.

### Step 4C: Optional Production-Style S3 Policy

For a tighter policy, replace broad S3 read access with a customer-managed policy scoped to your bucket:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::kg-lab-neptune-data-<unique-suffix>"
    },
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::kg-lab-neptune-data-<unique-suffix>/rdf/*"
    }
  ]
}
```

If the S3 objects use SSE-KMS encryption, also grant `kms:Decrypt` on the KMS key.

Minimum S3 permissions should allow:

```text
s3:GetObject
s3:ListBucket
```

Scope these permissions to the lab bucket.

Record the role ARN:

```text
arn:aws:iam::<your-account-id>:role/kg-lab-neptune-load-role
```

## Step 5: Associate The IAM Role With The Neptune Cluster

In the Neptune console:

1. Open the `kg-lab-neptune` cluster.
2. Find IAM roles or associated roles.
3. Add `kg-lab-neptune-load-role`.
4. Wait until the association is active.

## Step 6: Run The Loader

From Neptune Workbench, use a cell that can call the loader endpoint, or use a network path that can reach Neptune.

Loader request shape:

```json
{
  "source": "s3://kg-lab-neptune-data-<unique-suffix>/rdf/aircraft-sample.ttl",
  "format": "turtle",
  "iamRoleArn": "arn:aws:iam::<your-account-id>:role/kg-lab-neptune-load-role",
  "region": "us-east-1",
  "failOnError": "TRUE",
  "parallelism": "MEDIUM",
  "updateSingleCardinalityProperties": "FALSE",
  "parserConfiguration": {
    "namedGraphUri": "https://example.com/graph/aircraft-data"
  }
}
```

The HTTP endpoint is:

```text
https://<neptune-cluster-endpoint>:8182/loader
```

Use the **Writer** endpoint for bulk loading because the loader writes data into the graph.

From the Neptune console:

```text
Neptune -> Databases -> kg-lab-neptune -> Connectivity & Security -> Endpoints
```

Build the loader URL like this:

```text
Writer endpoint: <writer-endpoint>
Port: 8182
Path: /loader
HTTP endpoint: https://<writer-endpoint>:8182/loader
```

Related Neptune HTTP paths:

```text
Status: https://<writer-endpoint>:8182/status
SPARQL: https://<writer-endpoint>:8182/sparql
Loader: https://<writer-endpoint>:8182/loader
```

Do not use the reader endpoint for the loader. The reader endpoint is for read queries.

## Step 7: Check Load Status

The loader returns a load ID. Use it to check status:

```text
https://<neptune-cluster-endpoint>:8182/loader/<load-id>
```

Wait for the load status to complete.

## Step 8: Query Loaded Data

```sparql
%%sparql
PREFIX ex: <https://example.com/aero/>

SELECT ?aircraft ?tailNumber ?systemName ?partNumber ?outcome
WHERE {
  ?aircraft a ex:Aircraft ;
    ex:tailNumber ?tailNumber ;
    ex:hasSystem ?system .

  ?system ex:systemName ?systemName ;
    ex:hasPart ?part .

  ?part ex:partNumber ?partNumber .

  ?event a ex:MaintenanceEvent ;
    ex:performedOn ?part ;
    ex:outcome ?outcome .
}
ORDER BY ?aircraft
```

## Notes On Named Graphs

Plain Turtle does not carry named graph context. In Neptune, you can assign triple-based RDF loads to a named graph by using `parserConfiguration.namedGraphUri` in the loader request.

If you do not specify a graph for triples, Neptune uses its fallback named graph:

```text
http://aws.amazon.com/neptune/vocab/v01/DefaultNamedGraph
```

For datasets that already include graph names, use an RDF format that supports quads, such as N-Quads.

## Completion Check

You are done when:

- RDF data exists in S3.
- Neptune has an associated S3 loader role.
- The loader finishes successfully.
- SPARQL can query loaded data.
