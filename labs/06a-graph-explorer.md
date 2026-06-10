# Lab 06A: Visual Exploration With Graph Explorer

## Goal

Use Graph Explorer to visually inspect the RDF knowledge graph built in Labs 03-06.

Graph Explorer is useful for:

- Exploring neighborhoods around aircraft, systems, parts, risks, and requirements.
- Demonstrating graph relationships to non-SPARQL users.
- Checking whether loaded data looks connected as expected.
- Exporting screenshots or graph JSON for lightweight documentation.

It is not a replacement for SPARQL notebooks. Use SPARQL for precise query development and Graph Explorer for visual inspection and storytelling.

## What Graph Explorer Is

Graph Explorer is a web application for visualizing graph data. It supports property graphs through Gremlin and openCypher, and RDF graphs through SPARQL.

For this lab, use:

```text
Graph model: RDF
Query language: SPARQL
Database: Amazon Neptune Database
```

## How It Fits Our Lab

```text
SageMaker / Neptune Workbench
  -> Graph Explorer web UI
    -> Graph Explorer proxy
      -> Neptune RDF/SPARQL endpoint
        -> ontology graph and aircraft-data graph
```

Keep Neptune private. Do not make the Neptune cluster public just to use Graph Explorer.

## Step 1: Open Graph Explorer

If Graph Explorer is installed in your Neptune Workbench notebook, use the URL pattern:

```text
https://<notebook-name>.notebook.<region>.sagemaker.aws/proxy/9250/explorer/
```

Example shape:

```text
https://aws-neptune-kg-lab-notebook.notebook.us-east-1.sagemaker.aws/proxy/9250/explorer/
```

Your screen may already show:

```text
Connection: Default Connection
Graph | Data Table | Schema | Connections
```

## Step 2: Confirm The Connection

Open the **Connections** tab.

Expected settings for this lab:

```text
Query language: SPARQL
Using proxy server: true
Graph connection URL: https://<writer-endpoint>:8182
Service type: neptune-db
AWS region: us-east-1
AWS IAM auth enabled: false
```

Use the writer endpoint:

```text
https://kg-lab-neptune.cluster-xxxxxxxxxxxx.us-east-1.neptune.amazonaws.com:8182
```

If IAM DB authentication is enabled in a later security lab, Graph Explorer's proxy handles SigV4 signing, but the notebook or proxy environment must have AWS credentials and read permissions.

## Step 3: Add The Namespace Prefix

For RDF graphs, open the namespace panel if available.

Add:

```text
Prefix: ex
Namespace: https://example.com/aero/
```

This makes visual labels easier to read because full IRIs can be shortened.

## Step 4: Use Filter Search

In the right-side **Search** panel, use **Filter**.

Try:

```text
Node Label: Aircraft
Property: Resource URI or ID
Search string: Aircraft_001
Partial match: enabled
```

Then add the result to the graph.

If no result appears, use the **Query** tab instead. RDF search depends on the graph summary and how Graph Explorer detects `rdf:type` and properties.

## Step 5: Expand A Node

After adding `Aircraft_001`:

1. Double-click the aircraft node to expand first-order neighbors.
2. Use the Expand panel to limit results.
3. Expand from:

   ```text
   Aircraft_001 -> Engine_001
   Engine_001 -> Part_FuelPump_001
   Part_FuelPump_001 -> Risk_045
   Part_FuelPump_001 -> Req_ENG_001
   ```

This gives you a visual view of the same paths you queried in Lab 06.

## Step 6: Use SPARQL Query Search

Open:

```text
Search -> Query
```

For RDF visual graph results, prefer `CONSTRUCT` queries. `SELECT` is good for tabular answers, but `CONSTRUCT` returns RDF triples that Graph Explorer can draw as nodes and edges.

### Query 1: Aircraft 001 Context

```sparql
PREFIX ex: <https://example.com/aero/>

CONSTRUCT {
  ?aircraft a ex:Aircraft ;
    ex:tailNumber ?tailNumber ;
    ex:hasSystem ?system .

  ?system ex:systemName ?systemName ;
    ex:hasPart ?part .

  ?part ex:partNumber ?partNumber ;
    ex:suppliedBy ?supplier ;
    ex:linkedRequirement ?requirement ;
    ex:hasRisk ?risk .

  ?supplier ex:supplierName ?supplierName .
  ?requirement ex:requirementId ?requirementId .
  ?risk ex:riskId ?riskId ;
    ex:riskLevel ?riskLevel .
}
WHERE {
  GRAPH <https://example.com/graph/aircraft-data> {
    BIND(ex:Aircraft_001 AS ?aircraft)

    ?aircraft ex:tailNumber ?tailNumber ;
      ex:hasSystem ?system .

    ?system ex:systemName ?systemName .

    OPTIONAL {
      ?system ex:hasPart ?part .
      ?part ex:partNumber ?partNumber .

      OPTIONAL {
        ?part ex:suppliedBy ?supplier .
        ?supplier ex:supplierName ?supplierName .
      }

      OPTIONAL {
        ?part ex:linkedRequirement ?requirement .
        ?requirement ex:requirementId ?requirementId .
      }

      OPTIONAL {
        ?part ex:hasRisk ?risk .
        ?risk ex:riskId ?riskId ;
          ex:riskLevel ?riskLevel .
      }
    }
  }
}
LIMIT 100
```

Add all returned nodes and edges to the graph.

### Query 2: High-Risk Parts

```sparql
PREFIX ex: <https://example.com/aero/>

CONSTRUCT {
  ?aircraft ex:hasSystem ?system .
  ?system ex:hasPart ?part .
  ?part ex:hasRisk ?risk .
  ?part ex:partNumber ?partNumber .
  ?risk ex:riskId ?riskId ;
    ex:riskLevel ?riskLevel .
}
WHERE {
  GRAPH <https://example.com/graph/aircraft-data> {
    ?aircraft a ex:Aircraft ;
      ex:hasSystem ?system .

    ?system ex:hasPart ?part .

    ?part ex:partNumber ?partNumber ;
      ex:hasRisk ?risk .

    ?risk ex:riskId ?riskId ;
      ex:riskLevel ?riskLevel .

    FILTER (?riskLevel = "High")
  }
}
LIMIT 100
```

Use this to show which aircraft paths lead to high-risk records.

## Step 7: Use The Data Table

The lower **Data Table** panel shows what is currently in the visual graph.

Use it to:

- Filter visible resources.
- See resource URI, class, predicate, source, and target values.
- Export a CSV or JSON file.
- Hide noisy resources without clearing the graph.

## Step 8: Use The Schema Tab

Open **Schema**.

Use it to inspect:

```text
Classes / rdf:type values
Predicates
Which classes connect through which predicates
```

For our lab, look for:

```text
Aircraft
AircraftSystem
Part
Supplier
Requirement
RiskRecord
MaintenanceEvent
```

If the Schema tab looks empty, refresh or resync the schema. If it still looks empty, rely on the Query tab and SPARQL `CONSTRUCT` results.

## Step 9: Style Nodes

Use the node styling panel to make the graph readable:

```text
Aircraft display attribute: tailNumber
AircraftSystem display attribute: systemName
Part display attribute: partNumber
Supplier display attribute: supplierName
Requirement display attribute: requirementId
RiskRecord display attribute: riskId or riskLevel
MaintenanceEvent display attribute: eventType
```

Use distinct colors for:

```text
Aircraft
Systems
Parts
Risks
Requirements
Suppliers
Maintenance events
```

## Step 10: Save Evidence

Use Graph Explorer to:

- Download a screenshot.
- Save the graph view as JSON.
- Export the table view.

Suggested evidence:

```text
aircraft-001-context.png
aircraft-001-context.graph.json
high-risk-parts.png
high-risk-parts-table.csv
```

Do not commit screenshots that contain private endpoints, account IDs, or sensitive names if your repository is public.

## Common Issues

### No Results In Filter Search

Use the Query tab with `CONSTRUCT`.

Filter search depends on detected labels/classes and searchable properties. With RDF, node labels come from `rdf:type`, and properties are RDF predicates.

### Query Runs But Nothing Can Be Added

For RDF graph visualization, use `CONSTRUCT`.

`SELECT` is useful for tabular answers, but it may return scalar values rather than graph resources that can be added to the canvas.

### Connection Fails

Check:

- Neptune cluster is available.
- Notebook can run `%status`.
- Graph Explorer connection points to `https://<writer-endpoint>:8182`.
- Proxy mode is enabled.
- IAM auth setting matches the Neptune cluster setting.
- Graph Explorer is running inside the same VPC path, such as SageMaker/Workbench.

## Completion Check

You are done when:

- Graph Explorer connects to Neptune.
- You can add `Aircraft_001` to the graph.
- You can expand from aircraft to systems and parts.
- You can run a `CONSTRUCT` query and add results to the graph.
- You can use styling to make node labels readable.
- You can export a screenshot or graph JSON.

## References

- [AWS Graph Explorer GitHub repository](https://github.com/aws/graph-explorer)
- [Graph Explorer features](https://raw.githubusercontent.com/aws/graph-explorer/main/docs/features/README.md)
- [Graph Explorer graph view](https://raw.githubusercontent.com/aws/graph-explorer/main/docs/features/graph-view.md)
- [Connecting Graph Explorer to Neptune](https://github.com/aws/graph-explorer/blob/main/docs/guides/connecting-to-neptune.md)
- [Launching Graph Explorer using Amazon SageMaker](https://github.com/aws/graph-explorer/blob/main/docs/guides/deploy-to-sagemaker.md)

