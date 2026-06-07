# Lab 03: Neptune Workbench And First SPARQL

## Goal

Create a Neptune Workbench notebook, connect to the Neptune cluster, insert your first RDF triples, and query them with SPARQL.

## Architecture

```text
Neptune Workbench notebook
  -> runs inside AWS-managed notebook environment
  -> connects to Neptune in the VPC
  -> sends SPARQL queries to port 8182
```

Neptune Workbench gives you a browser-based notebook experience for querying and visualizing graph data.

## Step 1: Create A Notebook

If you created the notebook during Lab 02, skip to Step 2 after the notebook status becomes ready.

Also confirm the Neptune writer DB instance is `Available`. The notebook can become ready slightly before the writer instance finishes creating.

If you did not create a notebook during database creation, create one now in the Amazon Neptune console:

1. Go to **Notebooks**.
2. Choose **Create notebook**.
3. Select your Neptune Database cluster: `kg-lab-neptune`.
4. Notebook name: `kg-lab-notebook`.
5. Notebook instance type: `ml.t3.medium`.
6. IAM role: create a new role or select the lab notebook role.
7. Internet access: direct access through Amazon SageMaker.
8. Choose the same VPC/network context as your Neptune cluster.
9. Create the notebook.

Some console screens display a fixed notebook prefix such as `aws-neptune-`. If so, entering `kg-lab-notebook` may create a final notebook named `aws-neptune-kg-lab-notebook`.

Wait until the notebook status is ready.

## Step 2: Open JupyterLab

1. Select the notebook.
2. Choose **Open JupyterLab**.
3. Create a new notebook.
4. When prompted for a kernel, choose **Python 3**.

Do not choose PyTorch, TensorFlow, Sparkmagic, R, or No Kernel for the RDF/SPARQL labs.

If `Python 3` is not available, choose `conda_python3`, then run `%status`. If the graph notebook magics are not available, switch back to `Python 3` from the notebook kernel selector.

## Step 3: Check Neptune Status

Run this notebook cell:

```text
%status
```

Expected result:

- The notebook should return Neptune status information.
- If it fails, the notebook may not be connected to the correct cluster or network.

A healthy result should look similar to:

```text
status: healthy
dbEngineVersion: 1.4.7.0.R1
role: writer
sparql: version sparql-1.1
IAMAuthentication: disabled
serverlessConfiguration:
  minCapacity: 1.0
  maxCapacity: 16.0
```

The exact engine version may differ if AWS has released a newer default version.

## Step 4: Query The Empty Graph

Run:

```sparql
%%sparql
SELECT * WHERE {
  ?s ?p ?o
}
LIMIT 10
```

If the graph is empty, zero rows is fine.

## Step 5: Insert First RDF Triples

Run:

```sparql
%%sparql
PREFIX ex: <https://example.com/aero/>

INSERT DATA {
  GRAPH <https://example.com/graph/lab0> {
    ex:Aircraft_001 a ex:Aircraft ;
      ex:tailNumber "N001KG" ;
      ex:hasSystem ex:Engine_001 .

    ex:Engine_001 a ex:AircraftSystem ;
      ex:systemName "Left Engine" .
  }
}
```

## Step 6: Query The Inserted Data

Run:

```sparql
%%sparql
PREFIX ex: <https://example.com/aero/>

SELECT ?aircraft ?tailNumber ?system ?systemName
WHERE {
  GRAPH <https://example.com/graph/lab0> {
    ?aircraft a ex:Aircraft ;
      ex:tailNumber ?tailNumber ;
      ex:hasSystem ?system .

    ?system ex:systemName ?systemName .
  }
}
```

Expected result:

```text
aircraft: https://example.com/aero/Aircraft_001
tailNumber: N001KG
system: https://example.com/aero/Engine_001
systemName: Left Engine
```

## Step 7: Add A Maintenance Event

Run:

```sparql
%%sparql
PREFIX ex: <https://example.com/aero/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

INSERT DATA {
  GRAPH <https://example.com/graph/lab0> {
    ex:MaintEvent_1001 a ex:MaintenanceEvent ;
      ex:performedOn ex:Engine_001 ;
      ex:eventDate "2026-06-06"^^xsd:date ;
      ex:eventType "Inspection" ;
      ex:outcome "No fault found" .
  }
}
```

Then query:

```sparql
%%sparql
PREFIX ex: <https://example.com/aero/>

SELECT ?aircraft ?tailNumber ?systemName ?event ?eventType ?outcome
WHERE {
  GRAPH <https://example.com/graph/lab0> {
    ?aircraft a ex:Aircraft ;
      ex:tailNumber ?tailNumber ;
      ex:hasSystem ?system .

    ?system ex:systemName ?systemName .

    ?event a ex:MaintenanceEvent ;
      ex:performedOn ?system ;
      ex:eventType ?eventType ;
      ex:outcome ?outcome .
  }
}
```

## Completion Check

You are done when:

- `%status` works.
- You can insert RDF triples.
- You can query `Aircraft_001`.
- You understand that named graphs organize triples into logical datasets.

## Troubleshooting

If `%status` fails:

- Confirm the notebook and cluster are in the same region.
- Confirm the notebook is associated with the right Neptune cluster.
- Confirm the security group allows notebook-to-Neptune access.
- Confirm IAM database authentication is disabled for this first lab.
- Confirm you did not attach unrelated security groups that block notebook-to-cluster traffic.

### Timeout When Running `%status`

If `%status` returns a timeout like this:

```text
ConnectTimeoutError
Connection to <cluster-endpoint> timed out
port=8182
```

The notebook can resolve the Neptune endpoint, but it cannot open a network connection to port `8182`. This is usually a VPC or security group issue.

Check these in order:

1. Confirm the writer DB instance is available.

   ```text
   Neptune console -> Databases -> kg-lab-neptune
   Cluster row: Available
   Writer instance row: Available
   ```

2. Find the Neptune cluster security group.

   ```text
   Neptune console -> Databases -> kg-lab-neptune -> Connectivity & Security
   ```

   Record the VPC security group attached to the cluster.

3. Find the notebook security group.

   ```text
   SageMaker AI console -> Notebook instances -> aws-neptune-kg-lab-notebook
   ```

   Look in the notebook networking details and record the notebook security group.

4. Add an inbound rule to the Neptune cluster security group.

   ```text
   Type: Custom TCP
   Port: 8182
   Source: notebook security group
   Description: Allow Neptune Workbench notebook to connect to Neptune
   ```

   If the notebook and Neptune share the same security group, add a self-referencing inbound rule:

   ```text
   Type: Custom TCP
   Port: 8182
   Source: same security group ID
   Description: Allow Neptune clients in this security group
   ```

5. Confirm the Neptune cluster is not publicly accessible.

   ```text
   Publicly accessible: No
   ```

6. Restart the notebook kernel and run:

   ```text
   %status
   ```

Do not fix this by making Neptune public. Keep Neptune private and allow only the notebook security group to reach port `8182`.
