# Lab 08: Future Labs

## Goal

Extend the core Neptune RDF/SPARQL lab into advanced platform patterns.

## Track A: Federated SPARQL With Ontop

### Purpose

Learn how to query across:

```text
Materialized graph data in Neptune
Virtual graph data exposed by Ontop
```

### What You Will Build

- A small relational database with RMS-style records.
- Ontop mappings from relational tables to RDF.
- A virtual knowledge graph endpoint.
- A Neptune SPARQL query that uses `SERVICE` to reach the virtual graph.

### Key Design Questions

- Which data should be materialized in Neptune?
- Which data should stay virtual through Ontop?
- How will network access work between Neptune clients and Ontop?
- How will query performance be measured?
- What security boundary does each source require?

## Track B: SHACL Data Validation

### Purpose

Use SHACL to validate RDF data quality.

### Example Rules

- Every aircraft must have a tail number.
- Every part must have a part number.
- Every maintenance event must have an event date.
- Every risk record must have a risk level.

### Outcome

A validation layer that catches missing or malformed graph data before it becomes trusted.

## Track C: GenAI-Assisted Querying

### Purpose

Use GenAI to help users ask natural language questions over the graph while keeping query execution controlled and explainable.

### Safe Pattern

```text
User question
  -> LLM drafts SPARQL
    -> validator checks allowed graph terms
      -> read-only query runs in Neptune
        -> response includes graph evidence
```

### Example Questions

```text
Which aircraft have high-risk parts?
Which requirements are connected to failed inspections?
Which suppliers are linked to repeated anomalies?
```

### Controls

- Use read-only queries.
- Validate generated SPARQL.
- Restrict allowed prefixes, classes, and properties.
- Include source triples or query results in the final answer.
- Log generated queries for review.

## Track D: Ontology Change Control

### Purpose

Manage ontology changes as an engineering artifact.

### Recommended Artifacts

```text
ontology/
  aero-core.ttl
  aero-shapes.ttl
  examples/
queries/
  competency-questions/
docs/
  ontology-decision-records/
```

### Process

1. Capture the new competency question.
2. Identify the classes and properties needed.
3. Update ontology Turtle.
4. Add or update sample data.
5. Add SPARQL tests.
6. Run validation.
7. Document the decision.

## Track E: Production-Style Architecture Guide

### Purpose

Document how the lab would evolve into a controlled deployment.

### Topics

- VPC architecture.
- Private connectivity.
- IAM roles and policies.
- KMS encryption.
- Backup and restore.
- Monitoring and logging.
- Query performance.
- Deployment automation.
- Change control.
- Data loading pipeline.
- Disaster recovery assumptions.

## Completion Check

You are done when you can explain how the starter Neptune lab evolves into a broader ontology platform with federation, validation, GenAI, and operational discipline.

