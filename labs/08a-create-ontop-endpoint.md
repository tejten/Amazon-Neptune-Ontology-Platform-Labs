# Lab 08A: Create An Ontop SPARQL Endpoint

## Goal

Create an Ontop virtual knowledge graph endpoint that exposes relational RMS-style records as RDF and can be queried from Neptune with SPARQL `SERVICE`.

## What You Will Build

```text
EC2 instance in the Neptune VPC
  -> Docker
    -> PostgreSQL container with RMS sample table
    -> Ontop container exposing /sparql on port 8080
      -> Ontop mapping from SQL rows to RDF triples
        -> Neptune federated SERVICE query
```

## Why EC2 In The Same VPC

Neptune can run federated SPARQL queries with `SERVICE`, but the remote SPARQL endpoint must be accessible from Neptune's VPC path. A local Ontop endpoint on your laptop will not work for Neptune federation.

For this lab, run Ontop on an EC2 instance in the same VPC as `kg-lab-neptune`.

## Prerequisites

- Completed Labs 03-06.
- Neptune cluster is available.
- Neptune Workbench can run `%status`.
- You know the Neptune VPC ID.
- You have the files in `ontop-lab/`.

## Step 1: Find The Neptune VPC And Security Groups

In the Neptune console:

```text
Neptune -> Databases -> kg-lab-neptune -> Connectivity & Security
```

Record:

```text
VPC ID: <neptune-vpc-id>
Neptune security group: <neptune-sg-id>
Notebook security group: <notebook-sg-id>
```

Use your actual VPC ID and security group IDs.

## Step 2: Create An Ontop Security Group

Open:

```text
EC2 -> Security Groups -> Create security group
```

Use:

```text
Name: kg-lab-ontop-sg
Description: Ontop SPARQL endpoint for Neptune federation lab
VPC: same VPC as kg-lab-neptune
```

Inbound rules:

```text
Type: Custom TCP
Port: 8080
Source: <neptune-sg-id>
Description: Allow Neptune SERVICE calls to Ontop
```

Also add notebook access for testing:

```text
Type: Custom TCP
Port: 8080
Source: <notebook-sg-id>
Description: Allow Neptune Workbench to test Ontop
```

For administration, choose one:

```text
Preferred: use EC2 Instance Connect or Session Manager
Simple lab option: SSH port 22 from your current IP only
```

Do not open port `8080` to `0.0.0.0/0`.

Outbound rules:

```text
Allow all outbound
```

## Step 3: Launch An EC2 Instance

Open:

```text
EC2 -> Instances -> Launch instance
```

Use:

```text
Name: kg-lab-ontop
AMI: Amazon Linux 2023
Instance type: t3.small or t3.micro
VPC: same VPC as Neptune
Subnet: a subnet in that VPC
Auto-assign public IP: enabled for this beginner lab
Security group: kg-lab-ontop-sg
Storage: 20 GiB gp3 is fine
```

The public IP is only for you to administer the instance and pull Docker images. Neptune should use the EC2 instance's private IP or private DNS name.

## Step 4: Connect To The EC2 Instance

Use the EC2 console:

```text
EC2 -> Instances -> kg-lab-ontop -> Connect
```

Use **EC2 Instance Connect** if available.

## Step 5: Install Docker And Compose

On the EC2 instance:

```bash
sudo dnf update -y
sudo dnf install -y docker git
sudo systemctl enable --now docker
sudo usermod -aG docker ec2-user
newgrp docker
```

Install Docker Compose if `docker compose version` does not work:

```bash
mkdir -p ~/.docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
  -o ~/.docker/cli-plugins/docker-compose
chmod +x ~/.docker/cli-plugins/docker-compose
docker compose version
```

## Step 6: Create The Ontop Lab Files On EC2

Create a working directory:

```bash
mkdir -p ~/ontop-lab/input ~/ontop-lab/db ~/ontop-lab/jdbc ~/ontop-lab/queries
cd ~/ontop-lab
```

Copy the local `ontop-lab/` files from this repository into the EC2 directory.

Simple options:

- Commit the repo to GitHub and `git clone` it on the EC2 instance.
- Use the JupyterLab upload/download flow.
- Use `scp` from your laptop if SSH is configured.

## Step 7: Download The PostgreSQL JDBC Driver

Ontop needs a JDBC driver for the relational database.

On EC2:

```bash
cd ~/ontop-lab
curl -L https://jdbc.postgresql.org/download/postgresql-42.7.4.jar \
  -o jdbc/postgresql.jar
```

If a newer PostgreSQL JDBC driver is available, it is fine to use the newer stable version.

## Step 8: Create The Properties File

Copy the example properties file:

```bash
cp input/rms.properties.example input/rms.properties
```

For this Docker Compose lab, the example values are already correct:

```properties
jdbc.url=jdbc:postgresql://db:5432/rms
jdbc.driver=org.postgresql.Driver
jdbc.user=ontop
jdbc.password=ontop
```

In a real deployment, do not store database passwords in plain text files.

## Step 9: Start PostgreSQL And Ontop

From `~/ontop-lab`:

```bash
docker compose up -d
```

Check containers:

```bash
docker compose ps
docker compose logs -f ontop
```

Ontop may lazy-initialize on the first query.

## Step 10: Test Ontop Locally On EC2

Run:

```bash
curl -s http://localhost:8080/sparql \
  --data-urlencode 'query=PREFIX ex: <https://example.com/aero/>
SELECT ?rmsRecord ?rmsRecordId ?partNumber ?severity ?status
WHERE {
  ?rmsRecord a ex:RMSRecord ;
    ex:rmsRecordId ?rmsRecordId ;
    ex:affectedPartNumber ?partNumber ;
    ex:severity ?severity ;
    ex:status ?status .
}
ORDER BY ?rmsRecordId' \
  -H 'Accept: text/csv'
```

Expected rows:

```text
RMS-1001
RMS-1002
```

## Step 11: Get The Ontop Private Endpoint

On the EC2 instance details page, copy the private IP or private DNS.

Example:

```text
Private IP: 10.0.1.25
Ontop endpoint: http://10.0.1.25:8080/sparql
```

Use the private IP or private DNS in Neptune `SERVICE` queries.

## Step 12: Test From Neptune Workbench

In Neptune Workbench, test that the notebook can reach Ontop:

```python
import requests

query = """
PREFIX ex: <https://example.com/aero/>
SELECT ?rmsRecordId ?partNumber ?severity ?status
WHERE {
  ?rmsRecord a ex:RMSRecord ;
    ex:rmsRecordId ?rmsRecordId ;
    ex:affectedPartNumber ?partNumber ;
    ex:severity ?severity ;
    ex:status ?status .
}
ORDER BY ?rmsRecordId
"""

response = requests.post(
    "http://<ontop-private-ip>:8080/sparql",
    data={"query": query},
    headers={"Accept": "text/csv"},
    timeout=30,
)

print(response.status_code)
print(response.text)
```

Replace `<ontop-private-ip>` with your EC2 private IP.

## Step 13: Run A Neptune Federated Query

In Neptune Workbench:

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

  SERVICE <http://<ontop-private-ip>:8080/sparql> {
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

Expected result:

```text
Aircraft_001 | N001KG | FP-8842 | RMS-1001 | High | Open
Aircraft_002 | N002KG | FP-8842 | RMS-1001 | High | Open
```

## Troubleshooting

### Malformed Query Around `<ontop-host>`

If you see:

```text
MalformedQueryException
Encountered "<"
```

you still have the placeholder:

```sparql
SERVICE <http://<ontop-host>:8080/sparql>
```

Replace it with a real private IP or hostname:

```sparql
SERVICE <http://10.0.1.25:8080/sparql>
```

### Notebook Can Reach Ontop But Neptune Federation Fails

Check:

- Ontop security group allows inbound TCP `8080` from the Neptune security group.
- Ontop is using private IP or private DNS, not localhost.
- Ontop EC2 instance and Neptune are in the same VPC.
- Ontop container is listening on port `8080`.

### Ontop Starts But Queries Fail

Check:

- PostgreSQL container is running.
- `jdbc/postgresql.jar` exists.
- `input/rms.properties` exists.
- `input/rms.obda` exists.
- `input/aero-rms.owl` exists.
- `docker compose logs ontop` for mapping or JDBC errors.

## Pause And Cleanup

Pause:

```bash
docker compose down
```

Resume:

```bash
docker compose up -d
```

Full cleanup:

```bash
docker compose down -v
```

Also stop or terminate the EC2 instance when done to avoid charges.

## Completion Check

You are done when:

- Ontop is running at `http://<private-ip>:8080/sparql`.
- Ontop returns RMS records from PostgreSQL.
- Neptune Workbench can query Ontop directly.
- Neptune can run a federated `SERVICE` query against Ontop.
- You can explain virtual graph mapping: SQL row -> Ontop mapping -> RDF triple pattern.

## References

- [Ontop Docker endpoint tutorial](https://ontop-vkg.org/tutorial/endpoint/endpoint-docker.html)
- [Ontop CLI endpoint docs](https://ontop-vkg.org/guide/cli)
- [Ontop mapping language](https://ontop-vkg.org/guide/advanced/mapping-language.html)
- [Neptune SPARQL SERVICE federation](https://docs.aws.amazon.com/neptune/latest/userguide/sparql-service.html)

