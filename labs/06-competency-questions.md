# Lab 06: SPARQL Competency Questions

## Goal

Use SPARQL to answer practical questions from the aircraft maintenance and risk graph.

## What Are Competency Questions

Competency questions are questions the knowledge graph should be able to answer. They guide ontology design, data loading, validation, and query development.

Good competency questions are specific:

```text
Which aircraft have high-risk parts?
Which suppliers are linked to parts with repeated anomalies?
Which requirements are connected to failed inspections?
Which systems have maintenance events in the last 30 days?
```

## Query 1: Which Aircraft Have High-Risk Parts

```sparql
%%sparql
PREFIX ex: <https://example.com/aero/>

SELECT ?aircraft ?tailNumber ?systemName ?partNumber ?riskId ?riskLevel
WHERE {
  GRAPH <https://example.com/graph/aircraft-data> {
    ?aircraft a ex:Aircraft ;
      ex:tailNumber ?tailNumber ;
      ex:hasSystem ?system .

    ?system ex:systemName ?systemName ;
      ex:hasPart ?part .

    ?part ex:partNumber ?partNumber ;
      ex:hasRisk ?risk .

    ?risk ex:riskId ?riskId ;
      ex:riskLevel ?riskLevel .

    FILTER (?riskLevel = "High")
  }
}
ORDER BY ?tailNumber ?systemName
```

## Query 2: Which Requirements Are Linked To Risky Parts

```sparql
%%sparql
PREFIX ex: <https://example.com/aero/>

SELECT ?partNumber ?requirementId ?riskId ?riskLevel
WHERE {
  GRAPH <https://example.com/graph/aircraft-data> {
    ?part a ex:Part ;
      ex:partNumber ?partNumber ;
      ex:linkedRequirement ?requirement ;
      ex:hasRisk ?risk .

    ?requirement ex:requirementId ?requirementId .

    ?risk ex:riskId ?riskId ;
      ex:riskLevel ?riskLevel .
  }
}
ORDER BY ?riskLevel ?requirementId
```

## Query 3: Which Parts Had Anomaly Outcomes

```sparql
%%sparql
PREFIX ex: <https://example.com/aero/>

SELECT ?partNumber ?event ?eventType ?outcome
WHERE {
  GRAPH <https://example.com/graph/aircraft-data> {
    ?event a ex:MaintenanceEvent ;
      ex:performedOn ?part ;
      ex:eventType ?eventType ;
      ex:outcome ?outcome .

    ?part a ex:Part ;
      ex:partNumber ?partNumber .

    FILTER CONTAINS(LCASE(?outcome), "anomaly")
  }
}
ORDER BY ?partNumber
```

## Query 4: Which Suppliers Provide Parts On Aircraft

```sparql
%%sparql
PREFIX ex: <https://example.com/aero/>

SELECT DISTINCT ?supplierName ?partNumber ?tailNumber
WHERE {
  GRAPH <https://example.com/graph/aircraft-data> {
    ?aircraft a ex:Aircraft ;
      ex:tailNumber ?tailNumber ;
      ex:hasSystem ?system .

    ?system ex:hasPart ?part .

    ?part ex:partNumber ?partNumber ;
      ex:suppliedBy ?supplier .

    ?supplier ex:supplierName ?supplierName .
  }
}
ORDER BY ?supplierName ?partNumber
```

## Query 5: What Is The Connected Context Around One Aircraft

This query uses a property path to explore nearby facts.

```sparql
%%sparql
PREFIX ex: <https://example.com/aero/>

SELECT ?connected
WHERE {
  GRAPH <https://example.com/graph/aircraft-data> {
    ex:Aircraft_001 (ex:hasSystem|ex:hasPart|ex:suppliedBy|ex:hasRisk|ex:linkedRequirement)+ ?connected .
  }
}
```

## Exercise

Write three new competency questions before writing SPARQL.

Use this template:

```text
Question:
Why it matters:
Required classes:
Required properties:
Expected answer shape:
SPARQL query:
```

## Completion Check

You are done when:

- You can explain each query in plain English.
- You can modify filters and selected columns.
- You can write at least one new query from a competency question.
- You can identify when the ontology needs a new class or property.

