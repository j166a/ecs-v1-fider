# ECS Fargate Project - Fider

Production-grade deployment of [Fider](https://github.com/getfider/fider) on Amazon ECS using Fargate, private networking, RDS PostgreSQL, HTTPS, Amazon SES, Terraform and GitHub Actions.

## Overview

This project deploys Fider to AWS using a secure, repeatable and observable ECS architecture.

The solution includes:

- custom multi-stage Docker build
- statically linked Fider binary
- non-root `scratch` runtime
- Amazon ECR
- ECS Fargate
- private application workloads
- RDS PostgreSQL
- Application Load Balancer
- ACM-managed HTTPS
- Route 53 DNS
- Amazon SES
- IAM role separation
- SSM Parameter Store
- Terraform-managed infrastructure
- GitHub Actions CI/CD
- CloudWatch logging and monitoring

Application URL:

```text
https://fider.labs.imadahmed.uk
```

The parent domain is managed through Cloudflare, with `labs.imadahmed.uk` delegated to Amazon Route 53.

## Repository Structure

```text
01-ecs-v1/
├── Dockerfile
├── .dockerignore
├── .gitignore
├── README.md
├── docker-compose.yml
├── fider/
│   └── upstream Fider source
└── infra/
    ├── provider.tf
    ├── versions.tf
    ├── variables.tf
    ├── outputs.tf
    ├── main.tf
    └── modules/
        ├── vpc/
        ├── endpoints/
        ├── security/
        ├── ecr/
        ├── iam/
        ├── rds/
        ├── alb/
        ├── ecs/
        ├── acm/
        └── route53/
```

The root `Dockerfile` contains the custom production image.

The `fider/` directory contains the upstream Fider source plus the project-specific change that allows Amazon SES to use the AWS SDK credential chain and ECS task-role credentials rather than requiring static AWS credentials.

The `infra/` directory contains the Terraform implementation of the AWS infrastructure.

## Architecture

<!-- Add final architecture diagram here -->

The deployment uses a multi-AZ VPC design.

Public subnets contain the Application Load Balancer.

Private subnets contain:

- ECS Fargate tasks
- RDS PostgreSQL

Only the Application Load Balancer is publicly reachable.

ECS tasks do not receive public IP addresses and RDS is not publicly accessible.

AWS service access from private workloads uses VPC endpoints where appropriate.

## Application

Fider was selected because it provides a realistic production workload rather than a minimal demonstration application.

It includes:

- Go backend
- Node-based frontend build
- PostgreSQL
- database migrations
- server-side rendering
- email integration
- application health checks

Fider listens on port `3000`.

Health endpoint:

```text
/_health
```

The endpoint also verifies database connectivity.

Example:

```json
{"status":"Healthy"}
```

## Container Design

A custom multi-stage Dockerfile is used instead of the upstream pre-built Fider image.

Separate Go and Node builder stages produce the application binary and frontend assets before only the required runtime files are copied into the final image.

### Static Linking and Scratch Runtime

The initial runtime used:

```dockerfile
FROM debian:bookworm-slim
```

Inspection with `ldd` showed that the Fider binary was dynamically linked.

Disabling CGO was not viable because Fider depends on `v8go` and the V8 C++ runtime.

Instead, CGO was retained and the binary was externally linked as a static executable:

```dockerfile
RUN CGO_ENABLED=1 make build-server \
    LDFLAGS='-linkmode external -extldflags "-static"'
```

Verification:

```bash
ldd /app/fider
```

Result:

```text
not a dynamic executable
```

This allowed the production runtime to use:

```dockerfile
FROM scratch
```

Local image size reduced from approximately:

| Image | Local Size | ECR Compressed Size |
|---|---:|---:|
| Debian slim runtime | 826 MB | 340 MB |
| Scratch runtime | 353 MB | 148.1 MB |
| Reduction | ~57% | ~56% |

The final scratch runtime reduced the local image size from approximately 826 MB to 353 MB and the compressed ECR image size from approximately 340 MB to 148.1 MB, a reduction of about 56-57%.

The scratch image was validated for:

- PostgreSQL connectivity
- application startup
- background workers
- server-side rendering
- frontend rendering
- application health
- Docker health checks

### Non-Root Runtime

The application runs as a numeric non-root UID:

```dockerfile
USER 10001
```

Health check:

```dockerfile
HEALTHCHECK --timeout=5s CMD ["/app/fider", "ping"]
```

Application process:

```dockerfile
CMD ["/app/fider"]
```

## AWS Infrastructure

The infrastructure consists of:

- multi-AZ VPC
- public and private subnets
- Internet Gateway
- VPC endpoints
- security groups
- Amazon ECR
- ECS Fargate
- RDS PostgreSQL
- Application Load Balancer
- target group
- AWS Certificate Manager
- Route 53
- IAM roles and policies
- SSM Parameter Store
- CloudWatch

## Networking and Security

### Application Load Balancer

The ALB is deployed across public subnets and provides the only public application entry point.

Target group:

```text
Target type: IP
Protocol: HTTP
Port: 3000
Health path: /_health
```

Port `80` redirects to HTTPS on port `443`.

TLS terminates at the ALB using an ACM certificate.

### ECS

ECS tasks run in private subnets with public IP assignment disabled.

The ECS task security group accepts application traffic only from the ALB security group.

### RDS

RDS PostgreSQL runs in private subnets and is not publicly accessible.

PostgreSQL port `5432` is accessible only from the ECS task security group.

### IAM

Platform permissions and application permissions are separated.

**ECS task execution role**

Used by ECS for:

- pulling images from ECR
- publishing logs
- retrieving injected secrets and parameters

**Fider task role**

Used by the application for AWS API access, including Amazon SES.

This avoids long-lived AWS credentials and keeps application permissions separate from ECS platform permissions.

## Database Migrations

The upstream Fider container starts with:

```text
./fider migrate && ./fider
```

Running migrations during every application startup risks concurrent migration attempts during scaling or rolling deployments.

Migrations are therefore handled as a separate deployment step.

Migration command:

```text
/app/fider migrate
```

Application command:

```text
/app/fider
```

The migration runs as a one-off ECS task using the same immutable image and must complete successfully before the ECS service is updated.

## Email

Amazon SES provides production transactional email.

The SES identity for:

```text
imadahmed.uk
```

is verified using DKIM records managed through Cloudflare.

Fider's upstream SES implementation expects explicit AWS credentials.

The application was modified so that:

- explicitly supplied static credentials remain supported
- static credentials are no longer mandatory
- the AWS SDK default credential chain is used when credentials are absent

This allows Fider to authenticate using its ECS task role.

Application configuration includes:

```text
EMAIL=awsses
EMAIL_AWSSES_REGION=eu-west-2
EMAIL_NOREPLY=<verified-sender>
```

No AWS access key or secret access key is stored in the application environment.

## DNS and HTTPS

The parent domain:

```text
imadahmed.uk
```

is managed through Cloudflare.

The subdomain:

```text
labs.imadahmed.uk
```

is delegated to Route 53 using NS records.

Fider is served from:

```text
fider.labs.imadahmed.uk
```

A Route 53 alias record targets the Application Load Balancer.

HTTPS is provided by an ACM certificate attached to the ALB HTTPS listener.

## Secrets

Sensitive configuration is stored outside the repository.

Examples:

```text
/fider/JWT_SECRET
/fider/DATABASE_URL
```

Secrets are injected into ECS at runtime.

Application secrets and long-lived AWS credentials are not committed to Git.

## Infrastructure as Code

Terraform manages the AWS infrastructure.

```text
modules/
├── vpc/
├── endpoints/
├── security/
├── ecr/
├── iam/
├── rds/
├── alb/
├── ecs/
├── acm/
└── route53/
```

Terraform manages:

- networking and routing
- security groups
- VPC endpoints
- ECR
- IAM
- RDS
- ALB
- ECS
- ACM
- Route 53
- SSM configuration
- CloudWatch resources

Remote state is used so infrastructure state is not dependent on a developer workstation.

## CI/CD

GitHub Actions automates validation, image delivery and application deployment.

The pipeline:

- builds the container image
- scans it for vulnerabilities
- tags it with the Git commit SHA
- pushes it to Amazon ECR
- validates Terraform
- runs Terraform deployment steps
- runs database migrations as a one-off ECS task
- updates the ECS service
- performs a post-deployment health check

GitHub Actions authenticates to AWS using OIDC rather than long-lived access keys.

Container images use immutable Git commit SHA tags.

Deployment health checks and ECS deployment protection provide a failure boundary when a new version does not become healthy.

## Observability

Application logs are sent to CloudWatch Logs.

Monitoring covers relevant ALB, ECS and RDS metrics, including:

- unhealthy ALB targets
- ALB 5xx responses
- ECS CPU utilisation
- ECS memory utilisation
- RDS CPU utilisation
- RDS free storage
- RDS connections

## Engineering Decisions

### ClickOps Before Terraform

The infrastructure was initially deployed manually to validate the architecture and understand the AWS resources and dependencies involved.

This validated:

- VPC design
- security-group relationships
- ECS configuration
- RDS connectivity
- load balancing
- health checks
- DNS
- HTTPS

The ClickOps infrastructure was removed before rebuilding with Terraform.

### NAT Gateway vs VPC Endpoints

The initial ClickOps deployment used a NAT Gateway.

The Terraform architecture uses VPC endpoints where practical to provide private access to AWS services and reduce broad outbound internet access.

### MailHog vs Amazon SES

MailHog is used for local development.

Amazon SES is used for production transactional email.

### Static Credentials vs ECS Task Role

Static AWS credentials were rejected for application access to SES.

The AWS SDK credential chain allows the workload to obtain temporary credentials from its ECS task role.

### Debian vs Distroless vs Scratch

Debian slim, distroless and scratch were evaluated.

Scratch initially appeared unsuitable because the Fider binary was dynamically linked and depends on `v8go`.

Static external linking with CGO enabled produced a self-contained executable suitable for a scratch runtime.

### Database Migrations

Database migrations are separated from application startup to prevent concurrent migration attempts during ECS deployments.

### Terraform vs Terragrunt

Terraform is used directly.

Terragrunt was deferred because the project does not currently require the additional abstraction associated with multiple environments, accounts or shared infrastructure stacks.

## Troubleshooting Highlights

### RDS Connectivity

**Symptom:** ECS tasks timed out when connecting to PostgreSQL.

**Root cause:** The wrong security group was attached to the RDS instance.

**Resolution:** The dedicated RDS security group was attached and configured to allow PostgreSQL traffic only from the ECS task security group.

### SMTP Configuration

**Symptom:** Fider failed to start because `EMAIL_SMTP_HOST` was missing.

**Resolution:** MailHog SMTP configuration was supplied for local development before production email moved to SES.

### Docker DNS

**Symptom:** Fider could not resolve its PostgreSQL hostname.

**Root cause:** The application expected `db`, while the database container was named `postgres`.

**Resolution:** The Docker service name was aligned with the configured database hostname.

### Static Linking

**Symptom:** A `CGO_ENABLED=0` build failed with missing `v8go` symbols.

**Resolution:** CGO was retained and the Fider binary was externally linked using `-static`.

## Deployment Screenshots

### Application

<!-- Add final screenshot of https://fider.labs.imadahmed.uk -->

### ECS Service

<!-- Add final screenshot showing healthy ECS service/tasks -->

### Target Group

<!-- Add final screenshot showing healthy ALB targets -->

### HTTPS / Domain

<!-- Add final screenshot showing successful HTTPS deployment -->

## Reproduce the Setup

### Prerequisites

- Git
- Docker and Docker Compose
- AWS CLI
- Terraform
- GitHub CLI
- AWS account with sufficient provisioning permissions
- Domain capable of delegating `labs.imadahmed.uk` to Route 53
- AWS region: `eu-west-2`

### Local Configuration

- Create `.env` from the supplied example
- Configure:
  - `BASE_URL`
  - `DATABASE_URL`
  - `JWT_SECRET`
  - `EMAIL_NOREPLY`
  - SMTP settings for MailHog
- Generate a JWT secret with `openssl rand -hex 32`
- Keep `.env` outside Git

### Local Development

- Start the stack: `docker compose up -d --build`
- Run migrations: `docker compose run --rm app /app/fider migrate`
- Check containers: `docker compose ps`
- Validate health: `curl http://localhost/_health`
- Application: `http://localhost`
- MailHog: `http://localhost:8025`
- View logs: `docker compose logs -f app`
- Stop: `docker compose down`
- Remove local volumes if required: `docker compose down -v`

### AWS and DNS

- Verify AWS access: `aws sts get-caller-identity`
- Use AWS region `eu-west-2`
- Delegate `labs.imadahmed.uk` to the Route 53 hosted zone
- Verify delegation: `dig NS labs.imadahmed.uk`
- Verify the SES identity for `imadahmed.uk`
- Configure SES DKIM records
- Ensure SES production access is available for unrestricted transactional email

### Terraform Configuration

- Infrastructure directory: `infra/`
- Configure required Terraform variables for:
  - region
  - VPC and subnet CIDRs
  - application domain
  - Route 53 hosted zone
  - container image/tag
  - RDS configuration
  - Fider application configuration
- Store sensitive application values in SSM rather than Git
- Initialise: `terraform init`
- Format: `terraform fmt -recursive`
- Validate: `terraform validate`
- Review: `terraform plan`
- Deploy: `terraform apply`

### Container Image

- Production image is built from the root `Dockerfile`
- Images use immutable Git commit SHA tags
- Images are pushed to Amazon ECR
- CI/CD handles build, vulnerability scanning, tagging and push

### Database Migration

- Run `/app/fider migrate` as a one-off ECS task
- Migration must complete successfully before updating the ECS service
- Use the same immutable image as the application deployment

### Production Validation

- Health check: `curl https://fider.labs.imadahmed.uk/_health`
- Verify:
  - ECS tasks are healthy
  - ALB targets are healthy
  - HTTPS succeeds
  - HTTP redirects to HTTPS
  - RDS is reachable only from ECS
  - CloudWatch receives application logs
  - SES sends using the Fider task role

### CI/CD Setup

- Configure GitHub Actions OIDC trust with AWS
- Do not store long-lived AWS access keys in GitHub
- Pipeline responsibilities:
  - Terraform validation
  - container build and vulnerability scan
  - ECR push
  - infrastructure deployment
  - one-off database migration
  - ECS service update
  - post-deployment health check

## Teardown

- Destroy Terraform-managed infrastructure with `terraform destroy`
- Review the destroy plan before confirmation
- Document any intentionally retained infrastructure separately
