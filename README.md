# SimpleTimeService

A lightweight HTTP microservice written in Go that returns the current UTC timestamp and the visitor's IP address. The service is containerized, deployed on AWS EKS, and fully managed with Terraform.

## Overview

The service exposes a single endpoint `GET /` and responds with:

```json
{
  "timestamp": "2026-04-07T07:38:14Z",
  "ip": "203.0.113.42"
}
```

The IP detection handles real-world proxy and load balancer scenarios by reading `X-Forwarded-For` and `X-Real-IP` headers before falling back to the direct connection IP.

## Repository Structure

```
.
├── app/                        # Go application source and Dockerfile
│   ├── main.go
│   ├── go.mod
│   └── Dockerfile
├── microservice.yml            # Kubernetes Deployment and Service
├── terraform/                  # AWS infrastructure as code
│   ├── main.tf                 # VPC and EKS module configuration
│   ├── variables.tf
│   ├── terraform.tfvars
│   ├── outputs.tf
│   └── providers.tf
└── .github/
    └── workflows/
        └── docker-publish.yml  # CI/CD pipeline
```

## Tech Stack

- **Language** — Go (stdlib only, no external dependencies)
- **Container** — Docker multi-stage build with Alpine base, runs as non-root user
- **Orchestration** — Kubernetes (EKS)
- **Infrastructure** — Terraform using the [terraform-aws-modules/vpc](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest) and [terraform-aws-modules/eks](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) community modules
- **CI/CD** — GitHub Actions, auto-publishes image to DockerHub on every push

---

## Prerequisites

| Tool | Install |
|---|---|
| Go >= 1.22 | https://go.dev/doc/install |
| Docker | https://docs.docker.com/engine/install/ |
| kubectl | https://kubernetes.io/docs/tasks/tools/ |
| Terraform >= 1.6 | https://developer.hashicorp.com/terraform/install |
| AWS CLI v2 | https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html |

---

## Deploying the Microservice

The image is publicly available on DockerHub at `hemanthgangula/timeservice:latest`.

Deploy to any running Kubernetes cluster:

```bash
kubectl apply -f microservice.yml
```

Verify the pods are running:

```bash
kubectl get pods
kubectl get svc
```

Access the service:

```bash
kubectl port-forward svc/timeservice 8080:80
curl http://localhost:8080/
```

---

## Infrastructure — VPC + EKS on AWS

The infrastructure is fully managed with Terraform. It uses the official AWS community modules rather than building VPC and EKS resources from scratch, keeping the configuration concise and following AWS best practices out of the box.

### What gets created

- VPC with 2 public and 2 private subnets across 2 availability zones
- Internet Gateway + single NAT Gateway for outbound internet access from private subnets
- EKS cluster (Kubernetes v1.31)
- Managed node group with 2 worker nodes deployed on private subnets only

### AWS Authentication

Export your credentials as environment variables — never hardcode them:

```bash
export AWS_ACCESS_KEY_ID="your-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret-access-key"
export AWS_DEFAULT_REGION="us-east-1"
```

Verify:

```bash
aws sts get-caller-identity
```

### Deploy

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

After apply, configure kubectl using the output command:

```bash
aws eks update-kubeconfig --region us-east-1 --name timeservice-eks
kubectl get nodes
```

### Configuration

Key variables in `terraform/terraform.tfvars`:

| Variable | Default | Description |
|---|---|---|
| `aws_region` | `us-east-1` | AWS region |
| `cluster_name` | `timeservice-eks` | EKS cluster name |
| `cluster_version` | `1.31` | Kubernetes version |
| `node_instance_type` | `m6a.large` | Worker node instance type |
| `node_desired_count` | `2` | Number of worker nodes |

### Teardown

```bash
cd terraform
terraform destroy
```

---

## CI/CD Pipeline

Every push to `master` triggers a GitHub Actions workflow that builds the Docker image and pushes it to DockerHub. Each image is tagged with the git commit SHA for full traceability:

```
hemanthgangula/timeservice:sha-a1b2c3d
hemanthgangula/timeservice:latest
```

This makes it easy to trace exactly which commit is running in any environment.

To use this pipeline in your own fork, add the following secrets in GitHub → Settings → Secrets → Actions:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN` — create at DockerHub → Account Settings → Security → New Access Token

---

## Design Decisions

- **stdlib only** — no external Go dependencies, keeps the image small and reduces supply chain risk
- **Alpine base image** — lightweight and familiar, easy to shell into for debugging
- **Non-root user** — container runs as `appuser` (uid 1001), following container security best practices
- **ClusterIP service** — no external load balancer; use `kubectl port-forward` for local access or add an Ingress controller for production
- **Community Terraform modules** — the VPC and EKS modules are maintained by the terraform-aws-modules community and widely used in production, no need to reinvent the wheel

