# Lab 04: RDF/OWL Ontology Starter

## Goal

Create the first ontology slice for an aircraft maintenance and risk knowledge graph.

## Concepts

RDF represents facts as triples:

```text
subject predicate object
```

Example:

```text
Aircraft_001 hasSystem Engine_001
```

OWL lets you define classes, properties, and relationships with richer meaning. In this lab, you will create a small ontology and sample instance data.

## Starter Namespace

Use:

```text
https://example.com/aero/
```

For a real project, replace this with a stable organization-owned namespace.

## Core Classes

```text
Aircraft
AircraftSystem
Part
MaintenanceEvent
Inspection
Requirement
RiskRecord
Supplier
FailureMode
```

## Core Object Properties

```text
hasSystem
hasPart
performedOn
suppliedBy
linkedRequirement
hasRisk
hasFailureMode
```

## Core Data Properties

```text
tailNumber
systemName
partNumber
serialNumber
eventDate
eventType
outcome
requirementId
riskId
riskLevel
supplierName
```

## Step 1: Insert Ontology Terms

Run in Neptune Workbench:

```sparql
%%sparql
PREFIX ex: <https://example.com/aero/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

INSERT DATA {
  GRAPH <https://example.com/graph/ontology> {
    ex:Aircraft a owl:Class ;
      rdfs:label "Aircraft" .

    ex:AircraftSystem a owl:Class ;
      rdfs:label "Aircraft System" .

    ex:Part a owl:Class ;
      rdfs:label "Part" .

    ex:MaintenanceEvent a owl:Class ;
      rdfs:label "Maintenance Event" .

    ex:Requirement a owl:Class ;
      rdfs:label "Requirement" .

    ex:RiskRecord a owl:Class ;
      rdfs:label "Risk Record" .

    ex:Supplier a owl:Class ;
      rdfs:label "Supplier" .

    ex:FailureMode a owl:Class ;
      rdfs:label "Failure Mode" .

    ex:hasSystem a owl:ObjectProperty ;
      rdfs:domain ex:Aircraft ;
      rdfs:range ex:AircraftSystem .

    ex:hasPart a owl:ObjectProperty ;
      rdfs:domain ex:AircraftSystem ;
      rdfs:range ex:Part .

    ex:performedOn a owl:ObjectProperty ;
      rdfs:domain ex:MaintenanceEvent .

    ex:suppliedBy a owl:ObjectProperty ;
      rdfs:domain ex:Part ;
      rdfs:range ex:Supplier .

    ex:linkedRequirement a owl:ObjectProperty ;
      rdfs:range ex:Requirement .

    ex:hasRisk a owl:ObjectProperty ;
      rdfs:range ex:RiskRecord .

    ex:tailNumber a owl:DatatypeProperty ;
      rdfs:domain ex:Aircraft ;
      rdfs:range xsd:string .

    ex:partNumber a owl:DatatypeProperty ;
      rdfs:domain ex:Part ;
      rdfs:range xsd:string .

    ex:eventDate a owl:DatatypeProperty ;
      rdfs:domain ex:MaintenanceEvent ;
      rdfs:range xsd:date .
  }
}
```

## Step 2: Insert Sample Domain Data

```sparql
%%sparql
PREFIX ex: <https://example.com/aero/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

INSERT DATA {
  GRAPH <https://example.com/graph/aircraft-data> {
    ex:Aircraft_001 a ex:Aircraft ;
      ex:tailNumber "N001KG" ;
      ex:hasSystem ex:Engine_001 ;
      ex:hasSystem ex:Avionics_001 .

    ex:Engine_001 a ex:AircraftSystem ;
      ex:systemName "Left Engine" ;
      ex:hasPart ex:Part_FuelPump_001 .

    ex:Avionics_001 a ex:AircraftSystem ;
      ex:systemName "Primary Avionics" ;
      ex:hasPart ex:Part_Display_001 .

    ex:Part_FuelPump_001 a ex:Part ;
      ex:partNumber "FP-8842" ;
      ex:serialNumber "SN-FP-10001" ;
      ex:suppliedBy ex:Supplier_AeroPartsCo .

    ex:Part_Display_001 a ex:Part ;
      ex:partNumber "DSP-1200" ;
      ex:serialNumber "SN-DSP-20001" ;
      ex:suppliedBy ex:Supplier_SkySystems .

    ex:Supplier_AeroPartsCo a ex:Supplier ;
      ex:supplierName "AeroPartsCo" .

    ex:Supplier_SkySystems a ex:Supplier ;
      ex:supplierName "SkySystems" .

    ex:Req_ENG_001 a ex:Requirement ;
      ex:requirementId "ENG-001" ;
      ex:requirementText "Fuel delivery components must pass inspection every 180 days." .

    ex:Risk_045 a ex:RiskRecord ;
      ex:riskId "RISK-045" ;
      ex:riskLevel "High" ;
      ex:riskDescription "Repeated fuel pump inspection anomalies." .

    ex:Part_FuelPump_001 ex:linkedRequirement ex:Req_ENG_001 ;
      ex:hasRisk ex:Risk_045 .

    ex:MaintEvent_1001 a ex:MaintenanceEvent ;
      ex:performedOn ex:Part_FuelPump_001 ;
      ex:eventDate "2026-06-06"^^xsd:date ;
      ex:eventType "Inspection" ;
      ex:outcome "Anomaly observed" .
  }
}
```

## Step 3: Query Aircraft Systems And Parts

```sparql
%%sparql
PREFIX ex: <https://example.com/aero/>

SELECT ?aircraft ?tailNumber ?systemName ?partNumber ?supplierName
WHERE {
  GRAPH <https://example.com/graph/aircraft-data> {
    ?aircraft a ex:Aircraft ;
      ex:tailNumber ?tailNumber ;
      ex:hasSystem ?system .

    ?system ex:systemName ?systemName ;
      ex:hasPart ?part .

    ?part ex:partNumber ?partNumber ;
      ex:suppliedBy ?supplier .

    ?supplier ex:supplierName ?supplierName .
  }
}
ORDER BY ?systemName ?partNumber
```

## Step 4: Query Risks Linked To Parts

```sparql
%%sparql
PREFIX ex: <https://example.com/aero/>

SELECT ?partNumber ?riskId ?riskLevel ?riskDescription
WHERE {
  GRAPH <https://example.com/graph/aircraft-data> {
    ?part a ex:Part ;
      ex:partNumber ?partNumber ;
      ex:hasRisk ?risk .

    ?risk ex:riskId ?riskId ;
      ex:riskLevel ?riskLevel ;
      ex:riskDescription ?riskDescription .
  }
}
```

## Design Notes

- Keep ontology terms in a separate named graph from instance data.
- Start with competency questions before adding too many classes.
- Use stable IRIs for entities.
- Use labels for human readability.
- Use SHACL later for validation rules.

## Completion Check

You are done when:

- Ontology terms exist in `https://example.com/graph/ontology`.
- Sample data exists in `https://example.com/graph/aircraft-data`.
- You can query systems, parts, suppliers, requirements, and risks.

