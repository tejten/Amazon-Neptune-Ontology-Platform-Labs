# Lab 08: Advanced Platform Expansion

## Goal

Extend the starter Neptune RDF/SPARQL lab into a broader ontology platform design. This lab is a roadmap of advanced mini-labs rather than one single exercise.

You will expand into:

- Federated SPARQL with Ontop virtual knowledge graphs.
- SHACL validation before trusted graph loading.
- GenAI-assisted graph querying and GraphRAG patterns.
- Ontology maintenance and change control.
- Production-style architecture documentation.

## Starting Point

Before starting Lab 08, you should have completed:

```text
Lab 03: Workbench and first SPARQL
Lab 04: RDF/OWL ontology starter
Lab 05: S3 bulk load
Lab 06: Competency questions
Lab 07: Security and teardown basics
```

You should already have:

```text
Neptune cluster: kg-lab-neptune
Workbench notebook: aws-neptune-kg-lab-notebook
Named graph: https://example.com/graph/ontology
Named graph: https://example.com/graph/aircraft-data
S3 bucket: kg-lab-neptune-data-<unique-suffix>
Neptune load role: kg-lab-neptune-load-role
S3 Gateway VPC endpoint
```

## Track Map

| Track | Topic | Build |
| --- | --- | --- |
| 08A | Federated SPARQL with Ontop | Query Neptune RDF data plus virtual relational data. |
| 08B | SHACL validation | Validate RDF shape rules before loading trusted graph data. |
| 08C | GenAI-assisted querying | Add controlled natural language to SPARQL and GraphRAG patterns. |
| 08D | Ontology change control | Manage ontology changes as versioned engineering artifacts. |
| 08E | Production-style architecture | Document how the lab evolves into a controlled deployment. |

## Track 08A: Federated SPARQL With Ontop

### Purpose

Learn how to query across:

```text
Materialized RDF graph data in Amazon Neptune
Virtual RDF graph data exposed by Ontop
```

Ontop is a virtual knowledge graph system. It lets you expose relational data as RDF through mappings, then query that virtual graph with SPARQL.

### Architecture

```text
Neptune Workbench
  -> Neptune SPARQL endpoint
    -> materialized aircraft ontology/data
    -> SERVICE call to Ontop SPARQL endpoint
      -> Ontop mappings
        -> relational RMS-style tables
```

### Important Neptune Federation Rules

Neptune supports SPARQL federation with the `SERVICE` keyword.

Key constraints:

- `SERVICE` is for read operations.
- Remote SPARQL endpoints must be reachable from the Neptune VPC path.
- If multiple Neptune clusters use IAM authentication, federation has extra account, region, and permission constraints.
- You are responsible for the security and data-handling behavior of the remote endpoint.

### What You Will Build

Create a small relational table representing external RMS records:

```text
rms_record
  record_id
  affected_part_number
  severity
  status
  opened_date
  summary
```

Example records:

| record_id | affected_part_number | severity | status | opened_date | summary |
| --- | --- | --- | --- | --- | --- |
| RMS-1001 | FP-8842 | High | Open | 2026-06-01 | Fuel pump anomaly under review. |
| RMS-1002 | DSP-1200 | Medium | Closed | 2026-05-15 | Display flicker investigation closed. |

Expose the table through Ontop as virtual RDF:

```text
ex:RMSRecord_RMS-1001 a ex:RMSRecord ;
  ex:rmsRecordId "RMS-1001" ;
  ex:affectedPartNumber "FP-8842" ;
  ex:severity "High" ;
  ex:status "Open" ;
  ex:openedDate "2026-06-01"^^xsd:date ;
  ex:summary "Fuel pump anomaly under review." .
```

### Suggested Ontology Additions

The following snippet is Turtle syntax. Use it in a `.ttl` ontology file, not as a raw Python notebook cell:

```turtle
@prefix ex: <https://example.com/aero/> .
@prefix owl: <http://www.w3.org/2002/07/owl#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

ex:RMSRecord a owl:Class ;
  rdfs:label "RMS Record" .

ex:rmsRecordId a owl:DatatypeProperty ;
  rdfs:domain ex:RMSRecord ;
  rdfs:range xsd:string .

ex:affectedPartNumber a owl:DatatypeProperty ;
  rdfs:domain ex:RMSRecord ;
  rdfs:range xsd:string .

ex:severity a owl:DatatypeProperty ;
  rdfs:domain ex:RMSRecord ;
  rdfs:range xsd:string .

ex:status a owl:DatatypeProperty ;
  rdfs:domain ex:RMSRecord ;
  rdfs:range xsd:string .
```

To insert the same terms directly from Neptune Workbench, use a SPARQL cell instead:

```sparql
%%sparql
PREFIX ex: <https://example.com/aero/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

INSERT DATA {
  GRAPH <https://example.com/graph/ontology> {
    ex:RMSRecord a owl:Class ;
      rdfs:label "RMS Record" .

    ex:rmsRecordId a owl:DatatypeProperty ;
      rdfs:domain ex:RMSRecord ;
      rdfs:range xsd:string .

    ex:affectedPartNumber a owl:DatatypeProperty ;
      rdfs:domain ex:RMSRecord ;
      rdfs:range xsd:string .

    ex:severity a owl:DatatypeProperty ;
      rdfs:domain ex:RMSRecord ;
      rdfs:range xsd:string .

    ex:status a owl:DatatypeProperty ;
      rdfs:domain ex:RMSRecord ;
      rdfs:range xsd:string .
  }
}
```

If you see a Python `SyntaxError` such as `leading zeros in decimal integer literals are not permitted`, the cell is being interpreted as Python instead of Turtle or SPARQL. Add the `%%sparql` cell magic and use `PREFIX`, not Turtle `@prefix`, for direct notebook execution.

### Federated Query Pattern

This example joins materialized Neptune aircraft data to virtual Ontop RMS records by part number:

```sparql
%%sparql
PREFIX ex: <https://example.com/aero/>

SELECT ?aircraft ?tailNumber ?partNumber ?rmsRecordId ?severity ?status ?summary
WHERE {
  GRAPH <https://example.com/graph/aircraft-data> {
    ?aircraft a ex:Aircraft ;
      ex:tailNumber ?tailNumber ;
      ex:hasSystem ?system .

    ?system ex:hasPart ?part .

    ?part ex:partNumber ?partNumber .
  }

  SERVICE <http://<ontop-host>:8080/sparql> {
    ?rmsRecord a ex:RMSRecord ;
      ex:rmsRecordId ?rmsRecordId ;
      ex:affectedPartNumber ?partNumber ;
      ex:severity ?severity ;
      ex:status ?status ;
      ex:summary ?summary .
  }
}
ORDER BY ?tailNumber ?rmsRecordId
```

Replace `<ontop-host>` with a hostname reachable from the Neptune client path. For a real VPC lab, the Ontop endpoint should run in the same VPC or behind a VPC-reachable reverse proxy.

### Design Decision

Document why each data set is materialized or virtualized:

| Data | Pattern | Reason |
| --- | --- | --- |
| Aircraft ontology | Materialized in Neptune | Stable semantic model. |
| Aircraft/part graph | Materialized in Neptune | Frequent graph traversal. |
| RMS records | Virtual through Ontop | Operational data remains in relational source. |
| Historical maintenance events | Depends | Materialize if traversal-heavy; virtualize if source freshness matters more. |

### Completion Check

You are done when:

- Ontop exposes a SPARQL endpoint.
- A relational RMS table is mapped to RDF terms.
- Neptune can run a `SERVICE` query against the Ontop endpoint.
- The federated query joins aircraft parts to RMS records.
- You can explain materialized versus virtual tradeoffs.

## Track 08B: SHACL Data Validation

### Purpose

Use SHACL to validate RDF data before loading it as trusted graph data.

SHACL validation takes:

```text
Data graph
Shapes graph
```

and produces:

```text
Validation report
```

In this lab, SHACL is an external validation layer. Neptune stores RDF data, but the validation processor is separate from Neptune.

### What You Will Validate

Rules:

- Every aircraft must have exactly one tail number.
- Every part must have a part number.
- Every maintenance event must have an event date.
- Every maintenance event must point to the thing it was performed on.
- Every risk record must have a risk ID and risk level.

### Shapes Graph Example

Create a file named `aero-shapes.ttl`:

```turtle
@prefix ex: <https://example.com/aero/> .
@prefix sh: <http://www.w3.org/ns/shacl#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

ex:AircraftShape
  a sh:NodeShape ;
  sh:targetClass ex:Aircraft ;
  sh:property [
    sh:path ex:tailNumber ;
    sh:datatype xsd:string ;
    sh:minCount 1 ;
    sh:maxCount 1 ;
    sh:message "Aircraft must have exactly one tail number." ;
  ] .

ex:PartShape
  a sh:NodeShape ;
  sh:targetClass ex:Part ;
  sh:property [
    sh:path ex:partNumber ;
    sh:datatype xsd:string ;
    sh:minCount 1 ;
    sh:message "Part must have a part number." ;
  ] .

ex:MaintenanceEventShape
  a sh:NodeShape ;
  sh:targetClass ex:MaintenanceEvent ;
  sh:property [
    sh:path ex:eventDate ;
    sh:datatype xsd:date ;
    sh:minCount 1 ;
    sh:message "Maintenance event must have an event date." ;
  ] ;
  sh:property [
    sh:path ex:performedOn ;
    sh:minCount 1 ;
    sh:message "Maintenance event must point to the maintained asset." ;
  ] .

ex:RiskRecordShape
  a sh:NodeShape ;
  sh:targetClass ex:RiskRecord ;
  sh:property [
    sh:path ex:riskId ;
    sh:datatype xsd:string ;
    sh:minCount 1 ;
    sh:message "Risk record must have a risk ID." ;
  ] ;
  sh:property [
    sh:path ex:riskLevel ;
    sh:in ("Low" "Medium" "High") ;
    sh:minCount 1 ;
    sh:message "Risk level must be Low, Medium, or High." ;
  ] .
```

### Negative Test Data

Create intentionally bad RDF:

```turtle
@prefix ex: <https://example.com/aero/> .

ex:Aircraft_Bad_001 a ex:Aircraft .

ex:Risk_Bad_001 a ex:RiskRecord ;
  ex:riskLevel "Severe" .
```

Expected validation failures:

```text
Aircraft_Bad_001 is missing ex:tailNumber
Risk_Bad_001 is missing ex:riskId
Risk_Bad_001 has an invalid ex:riskLevel
```

### Validation Workflow

Use any SHACL processor you prefer. The workflow is:

```text
RDF source file
  -> SHACL validation
    -> if conforming, upload to S3
      -> Neptune bulk load
    -> if non-conforming, reject and send report to data owner
```

### Pipeline Gate

Add this rule to future data loads:

```text
No RDF file is loaded into the trusted named graph until SHACL validation passes.
```

Suggested named graphs:

```text
https://example.com/graph/staging
https://example.com/graph/trusted
https://example.com/graph/validation-results
```

### Completion Check

You are done when:

- You can explain the difference between ontology modeling and SHACL validation.
- You have at least four SHACL rules.
- You can validate good and bad data.
- You can explain where validation belongs in the load pipeline.

## Track 08C: GenAI-Assisted Querying

### Purpose

Use GenAI to help users ask natural-language questions over the graph while keeping query execution controlled, read-only, and explainable.

There are two useful patterns:

```text
Pattern 1: Custom natural language to SPARQL over Neptune Database
Pattern 2: Managed GraphRAG with Bedrock Knowledge Bases and Neptune Analytics
```

### Pattern 1: Natural Language To SPARQL

Architecture:

```text
User question
  -> ontology-aware prompt
    -> model drafts SPARQL
      -> validator checks query safety
        -> read-only query runs in Neptune
          -> answer includes result rows and provenance
```

### Safe Query Rules

Allow:

```text
SELECT
ASK
CONSTRUCT for explainable evidence, if needed
```

Block:

```text
INSERT
DELETE
DROP
CLEAR
LOAD
CREATE
SERVICE to unapproved endpoints
```

Require:

```text
Allowed prefixes only
Allowed named graphs only
LIMIT on exploratory queries
No unbounded SERVICE calls
No write operations
Human review for new query patterns
```

### Ontology Context For The Model

Give the model a compact schema card:

```text
Classes:
- ex:Aircraft
- ex:AircraftSystem
- ex:Part
- ex:MaintenanceEvent
- ex:Requirement
- ex:RiskRecord
- ex:Supplier

Object properties:
- ex:hasSystem: Aircraft -> AircraftSystem
- ex:hasPart: AircraftSystem -> Part
- ex:performedOn: MaintenanceEvent -> Part or AircraftSystem
- ex:suppliedBy: Part -> Supplier
- ex:linkedRequirement: Part -> Requirement
- ex:hasRisk: Part -> RiskRecord

Data properties:
- ex:tailNumber
- ex:systemName
- ex:partNumber
- ex:eventDate
- ex:eventType
- ex:outcome
- ex:requirementId
- ex:riskId
- ex:riskLevel
- ex:supplierName
```

### Prompt Template

```text
You translate user questions into read-only SPARQL for Amazon Neptune.

Use only these prefixes:
PREFIX ex: <https://example.com/aero/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

Use only this named graph:
https://example.com/graph/aircraft-data

Allowed query forms: SELECT and ASK.
Never use INSERT, DELETE, DROP, CLEAR, CREATE, LOAD, or unapproved SERVICE.
Always include LIMIT 50 unless the question asks for a count.

Return only SPARQL.

User question:
{question}
```

### Example User Question

```text
Which aircraft have high-risk parts?
```

Expected generated query:

```sparql
PREFIX ex: <https://example.com/aero/>

SELECT ?aircraft ?tailNumber ?partNumber ?riskId ?riskLevel
WHERE {
  GRAPH <https://example.com/graph/aircraft-data> {
    ?aircraft a ex:Aircraft ;
      ex:tailNumber ?tailNumber ;
      ex:hasSystem ?system .

    ?system ex:hasPart ?part .

    ?part ex:partNumber ?partNumber ;
      ex:hasRisk ?risk .

    ?risk ex:riskId ?riskId ;
      ex:riskLevel ?riskLevel .

    FILTER (?riskLevel = "High")
  }
}
LIMIT 50
```

### Pattern 2: Managed GraphRAG

Amazon Bedrock Knowledge Bases offers managed GraphRAG using Amazon Neptune Analytics graphs. This is separate from the Neptune Database RDF/SPARQL cluster used in Labs 03-06.

Use this pattern when you want:

- Document ingestion from S3.
- Automatic entity and relationship extraction.
- Graph-enhanced retrieval.
- Managed integration with foundation models.

Important distinction:

```text
Neptune Database: RDF/SPARQL ontology graph used in these labs.
Neptune Analytics: analytics graph service used by Bedrock Knowledge Bases GraphRAG.
```

### GenAI Completion Check

You are done when:

- You can explain custom natural language to SPARQL versus managed GraphRAG.
- You have a schema card.
- You have a safe prompt template.
- You have a query validator plan.
- You can show generated SPARQL, result rows, and source evidence.

## Track 08D: Ontology Change Control

### Purpose

Manage ontology changes as versioned engineering artifacts.

The ontology should not evolve through ad hoc notebook cells. Treat it like code.

### Recommended Repository Structure

```text
ontology/
  aero-core.ttl
  aero-shapes.ttl
  examples/
    aircraft-sample.ttl
    bad-aircraft-sample.ttl
queries/
  competency-questions/
    cq-001-high-risk-parts.rq
    cq-002-requirements-linked-to-risk.rq
    cq-003-connected-aircraft-context.rq
docs/
  ontology-decision-records/
    odr-001-aircraft-system-part-model.md
    odr-002-risk-record-model.md
  architecture/
    neptune-nonprod-architecture.md
```

### Change Categories

| Change type | Example | Review level |
| --- | --- | --- |
| Label/comment | Improve `rdfs:label` | Low |
| New data property | Add `ex:inspectionIntervalDays` | Medium |
| New object property | Add `ex:impactsRequirement` | Medium |
| New class | Add `ex:InspectionProgram` | Medium |
| Domain/range change | Change `ex:performedOn` semantics | High |
| IRI rename | Rename `ex:RiskRecord` | High |
| Delete term | Remove `ex:hasRisk` | High |

### Ontology Decision Record Template

```markdown
# ODR-000: <Decision Title>

## Status

Proposed | Accepted | Superseded

## Date

YYYY-MM-DD

## Competency Question

What question does this change help answer?

## Decision

What changed in the ontology?

## Rationale

Why is this model better than alternatives?

## Alternatives Considered

What else was considered?

## Impact

Affected classes, properties, queries, and data loads.

## Validation

SHACL rules and SPARQL regression queries.
```

### Change Workflow

```text
1. Capture competency question.
2. Propose ontology change.
3. Update ontology Turtle.
4. Update SHACL shapes.
5. Update sample data.
6. Run validation.
7. Run SPARQL regression queries.
8. Review with domain SME.
9. Record ODR.
10. Load into staging graph.
11. Promote to trusted graph.
```

### Regression Query Pattern

Every ontology change should preserve or intentionally change existing competency query behavior.

Example regression check:

```sparql
PREFIX ex: <https://example.com/aero/>

SELECT (COUNT(*) AS ?highRiskPartCount)
WHERE {
  GRAPH <https://example.com/graph/aircraft-data> {
    ?part a ex:Part ;
      ex:hasRisk ?risk .

    ?risk ex:riskLevel "High" .
  }
}
```

Record expected result:

```text
highRiskPartCount >= 1
```

### Completion Check

You are done when:

- Ontology files live outside notebook cells.
- Changes are tied to competency questions.
- SHACL and SPARQL tests are updated with ontology changes.
- At least one ODR is written.
- You can explain how to promote staging graph data to trusted graph data.

## Track 08E: Production-Style Architecture Guide

### Purpose

Document how this non-production lab would evolve into a controlled deployment.

This is not a production build. It is an architecture guide that describes what would change.

### Reference Architecture

```text
Private VPC
  -> private subnets across Availability Zones
  -> Neptune Database cluster
  -> Neptune Workbench or controlled client host
  -> S3 Gateway VPC endpoint
  -> CloudWatch logs and metrics
  -> KMS encryption
  -> IAM DB authentication
  -> CI/CD pipeline for ontology and data loads
  -> optional Ontop endpoint in private subnet
  -> optional GenAI application layer
```

### Security Architecture Topics

Document:

- VPC and subnet design.
- Security group rules.
- Private access path for notebooks and clients.
- IAM DB authentication plan.
- SigV4 signing requirement.
- S3 bucket policy for bulk loads.
- S3 Gateway endpoint.
- KMS key ownership and rotation.
- Least-privilege loader role.
- Separation of staging and trusted named graphs.

### Data Architecture Topics

Document:

- Ontology named graph.
- Trusted data named graph.
- Staging data named graph.
- Validation results graph.
- Source-to-ontology mapping.
- Bulk-load file formats.
- Naming and IRI strategy.
- Data refresh cadence.
- Lineage and provenance.

### Operations Topics

Document:

- Backup and restore.
- Snapshot retention.
- Pause/resume for non-production.
- Monitoring and alerting.
- Query logs.
- Slow query review.
- SPARQL `EXPLAIN` usage.
- Cost controls.
- Capacity assumptions.
- Change calendar.

### Deployment Guide Outline

```markdown
# Neptune Ontology Platform Deployment Guide

## Scope

## Environments

## Network Architecture

## IAM And Authentication

## Encryption

## S3 Bulk Load Setup

## Ontology Deployment

## Data Load Process

## Validation Process

## Monitoring

## Backup And Restore

## Federation

## GenAI Integration

## Teardown

## Known Limitations
```

### Completion Check

You are done when:

- You can draw the non-production architecture.
- You can explain each AWS service in the design.
- You can explain how data moves from source to S3 to Neptune.
- You can explain where validation, security, and change control happen.
- You have a deployment guide outline ready to fill in.

## Final Capstone

Create a short platform brief that answers:

```text
1. What business questions does the graph answer?
2. What ontology terms are currently modeled?
3. What data is materialized in Neptune?
4. What data could be virtualized with Ontop?
5. How is RDF data validated before loading?
6. How are ontology changes controlled?
7. How could GenAI safely query the graph?
8. What would change for production?
```

## Reference Documentation

- [Amazon Neptune SPARQL federation with SERVICE](https://docs.aws.amazon.com/neptune/latest/userguide/sparql-service.html)
- [Ontop getting started](https://ontop-vkg.org/guide/getting-started.html)
- [W3C SPARQL 1.1 Federated Query](https://www.w3.org/TR/sparql11-federated-query/)
- [W3C SHACL](https://www.w3.org/TR/shacl/)
- [Amazon Bedrock Knowledge Bases with Neptune Analytics GraphRAG](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-build-graphs.html)
- [Neptune IAM authentication](https://docs.aws.amazon.com/neptune/latest/userguide/iam-auth.html)
- [Connecting to Neptune with IAM authentication](https://docs.aws.amazon.com/neptune/latest/userguide/iam-auth-connecting.html)
