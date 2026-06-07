# Amazon Neptune Ontology Platform Labs

This repository is a hands on learning path for building an RDF knowledge graph platform on Amazon Neptune. The labs start with AWS account and CLI basics, then progress into Neptune setup, RDF/OWL modeling, SPARQL queries, bulk loading, security, federated query design, and GenAI assisted graph workflows.

The example domain is an aeronautics style knowledge graph with aircraft, systems, parts, maintenance events, requirements, inspections, risk records, and suppliers. The goal is to learn the platform patterns using realistic but non-sensitive sample data.

## What You Will Build

By the end of the lab sequence, you will have:

- A non-production Amazon Neptune Database environment.
- A Neptune Workbench notebook for interactive SPARQL queries.
- A starter RDF/OWL ontology for an aircraft maintenance and risk domain.
- Sample RDF data organized with named graphs.
- SPARQL queries that answer business oriented competency questions.
- An S3-based RDF bulk load workflow.
- A basic security model using VPC controls, IAM, encryption, and least-privilege thinking.
- A roadmap for federated SPARQL with Ontop virtual knowledge graphs.
- A roadmap for GenAI assisted natural language to SPARQL and graph grounded answers.
- A repeatable documentation structure for future ontology and platform changes.

## Lab Map

| Lab | Topic | Outcome |
| --- | --- | --- |
| 00 | AWS CLI baseline | Confirm profile, region, account, and caller identity. |
| 01 | Cost and account safety | Create budget alerts and define lab safety rules. |
| 02 | Create Neptune cluster | Provision a small non-production Neptune Database cluster. |
| 03 | Workbench and first SPARQL | Connect through Neptune Workbench and insert/query the first triples. |
| 04 | RDF/OWL ontology starter | Build the first ontology slice for aircraft, systems, parts, maintenance, requirements, and risks. |
| 05 | S3 bulk load | Load RDF data from Amazon S3 into Neptune. |
| 06 | Competency questions | Write SPARQL queries that answer practical domain questions. |
| 07 | Security and teardown | Apply security controls and clean up resources safely. |
| 08 | Advanced platform expansion | Extend into Ontop federation, SHACL validation, GenAI, change control, and production-style documentation. |

## Repository Layout

```text
.
├── README.md
└── labs/
    ├── 00-aws-cli-baseline.md
    ├── 01-cost-and-account-safety.md
    ├── 02-create-neptune-cluster.md
    ├── 03-workbench-first-sparql.md
    ├── 04-rdf-owl-ontology-starter.md
    ├── 05-s3-bulk-load.md
    ├── 06-competency-questions.md
    ├── 07-security-and-teardown.md
    └── 08-future-labs.md
```

## Assumptions

These labs assume:

- You have an AWS account.
- You have AWS CLI installed and configured.
- You can use the AWS Management Console.
- Your lab region is `us-east-1`.
- You are building a non-production environment.
- You are using Amazon Neptune Database for RDF/SPARQL.


## Current Starting Point

Before creating Neptune, confirm your AWS CLI context:

```bash
aws configure list
aws sts get-caller-identity
aws configure get region
```

You should know:

```text
AWS CLI profile: <your-profile>
AWS region: us-east-1
AWS account: <your-account-id>
Caller ARN: arn:aws:iam::<your-account-id>:user/<your-user>
```

## Cost Awareness

Amazon Neptune, Neptune Workbench, S3, backups, and related AWS services may incur charges. Create an AWS Budget before provisioning resources and delete lab resources when you are finished.

Recommended lab controls:

- Use one AWS region.
- Use clear resource names with a lab prefix.
- Use Neptune Serverless with the lowest capacity range the console accepts for beginner labs. In the current console flow, use `1` minimum NCU and `16` maximum NCUs.
- Use Neptune Standard storage for the beginner lab unless you are intentionally testing an I/O-heavy workload.
- Add tags such as `Project`, `Environment`, and `Owner`.
- Keep backup retention low for temporary labs.
- Keep IAM database authentication off for the first connectivity lab, then enable it later during the security lab.
- Disable deletion protection only for temporary lab resources.
- Delete notebooks, clusters, snapshots, and S3 objects when finished.
- Because the current console may require a `16` NCU maximum, keep the lab small and tear down resources when not in use.

## Reference Documentation

- [Amazon Neptune User Guide](https://docs.aws.amazon.com/neptune/latest/userguide/intro.html)
- [Launching a Neptune DB cluster using the console](https://docs.aws.amazon.com/neptune/latest/userguide/manage-console-launch-console.html)
- [Using Amazon Neptune with graph notebooks](https://docs.aws.amazon.com/neptune/latest/userguide/graph-notebooks.html)
- [Accessing the Neptune graph using SPARQL](https://docs.aws.amazon.com/neptune/latest/userguide/access-graph-sparql.html)
- [Bulk loading data into Neptune](https://docs.aws.amazon.com/neptune/latest/userguide/bulk-load.html)
- [Neptune IAM authentication](https://docs.aws.amazon.com/neptune/latest/userguide/iam-auth.html)
- [W3C RDF 1.1 Concepts](https://www.w3.org/TR/rdf11-concepts/)
- [W3C SPARQL 1.1 Query Language](https://www.w3.org/TR/sparql11-query/)
- [W3C OWL 2 Primer](https://www.w3.org/TR/owl-primer/)
- [W3C SHACL](https://www.w3.org/TR/shacl/)
