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

In the Amazon Neptune console:

1. Go to **Notebooks**.
2. Choose **Create notebook**.
3. Select your Neptune Database cluster: `kg-lab-neptune`.
4. Notebook name: `kg-lab-notebook`.
5. Choose a small notebook instance type.
6. Let the console create or select the required IAM role.
7. Choose the same VPC/network context as your Neptune cluster.
8. Create the notebook.

Wait until the notebook status is ready.

## Step 2: Open JupyterLab

1. Select the notebook.
2. Choose **Open JupyterLab**.
3. Create a new notebook.

## Step 3: Check Neptune Status

Run this notebook cell:

```text
%status
```

Expected result:

- The notebook should return Neptune status information.
- If it fails, the notebook may not be connected to the correct cluster or network.

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

