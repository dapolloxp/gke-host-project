# GCP Shared VPC with GKE Terraform Project

This Terraform project creates a Google Cloud Platform (GCP) infrastructure with a shared VPC architecture, including:

- **Host VPC Project**: Contains the shared VPC network, subnets, and networking resources
- **Service Project**: Contains the GKE cluster that uses the shared VPC

## Architecture

This project implements a GCP Shared VPC architecture following Google Cloud best practices for network isolation and security:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Host Project (networkpatterns)               │
│                         Networking Layer                        │
├─────────────────────────────────────────────────────────────────┤
│ ┌─ Shared VPC Host Project                                     │
│ │  ├─ VPC Network (shared-vpc) - Global routing               │
│ │  ├─ Regional Subnet (10.0.0.0/24)                          │
│ │  │  ├─ Secondary Range: pods (10.1.0.0/16)                 │
│ │  │  └─ Secondary Range: services (10.2.0.0/16)             │
│ │  ├─ Cloud Router + NAT Gateway                              │
│ │  ├─ Firewall Rules (internal communication)                │
│ │  └─ IAM: Shared VPC Host enablement                        │
│ └─────────────────────────────────────────────────────────────│
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ Shared VPC Connection
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                Service Project (networkpatterns2)               │
│                       Workloads Layer                          │
├─────────────────────────────────────────────────────────────────┤
│ ┌─ GKE Service Project                                         │
│ │  ├─ API Enablement (Container, Compute, Resource Manager)   │
│ │  ├─ Shared VPC Service Project attachment                   │
│ │  ├─ IAM Bindings:                                           │
│ │  │  ├─ GKE Service Account → Host Project permissions       │
│ │  │  └─ Compute Service Account → Subnet permissions         │
│ │  ├─ Private GKE Cluster                                     │
│ │  │  ├─ Private nodes (no external IPs)                     │
│ │  │  ├─ Workload Identity enabled                           │
│ │  │  ├─ Network Policy (Calico)                             │
│ │  │  ├─ Binary Authorization                                │
│ │  │  └─ Regional cluster deployment                         │
│ │  └─ Node Pool                                               │
│ │     ├─ Auto-scaling (1-5 nodes)                            │
│ │     ├─ Shielded GKE nodes                                  │
│ │     └─ Custom node service account                         │
│ └─────────────────────────────────────────────────────────────│
└─────────────────────────────────────────────────────────────────┘
```

### Key Architectural Components:

**Network Separation:**
- Host project manages all networking resources
- Service project contains only compute workloads (GKE)
- Cross-project IAM permissions enable secure resource sharing

**Security Features:**
- Private GKE nodes with no external IP addresses
- Outbound internet access via Cloud NAT in host project
- Network policies enabled for pod-to-pod communication control
- Binary authorization for container image security
- Shielded GKE nodes with secure boot and integrity monitoring

**IP Address Management:**
- Primary subnet: Node IP addresses (10.0.0.0/24)
- Secondary range "pods": Pod IP addresses (10.1.0.0/16)  
- Secondary range "services": Service IP addresses (10.2.0.0/16)

**IAM & Service Accounts:**
- Automatic GKE service account permissions on host project
- Default Compute Engine service account subnet access
- Custom node service account with minimal required permissions
- Workload Identity for secure pod-to-GCP authentication

## Prerequisites

1. Two GCP projects:
   - Host project (for networking) - will be automatically enabled as shared VPC host
   - Service project (for GKE) - will be automatically attached to shared VPC
2. Required APIs enabled manually (not managed by Terraform):
   ```bash
   # For service project:
   gcloud services enable container.googleapis.com compute.googleapis.com cloudresourcemanager.googleapis.com --project=YOUR_SERVICE_PROJECT_ID
   
   # For host project (if needed):
   gcloud services enable compute.googleapis.com cloudresourcemanager.googleapis.com --project=YOUR_HOST_PROJECT_ID
   ```
3. Appropriate IAM permissions:
   - `compute.xpnAdmin` role on the host project (for managing shared VPC)
   - `compute.networkAdmin` role on the host project (for network management)
   - `container.admin` role on the service project (for GKE management)
   - GKE service account permissions are automatically granted by Terraform
4. Terraform >= 1.0

## Usage

### Quick Start with Make

1. **View available commands:**
   ```bash
   make help
   ```

2. **Setup development environment:**
   ```bash
   make setup
   ```

3. **Update project configuration:**
   Edit `terraform.tfvars` with your project IDs

4. **Deploy infrastructure:**
   ```bash
   make apply
   ```

5. **Deploy applications:**
   ```bash
   make build-podman
   make deploy-podman
   ```

### Manual Terraform Usage

1. **Copy the example variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars with your project IDs:**
   ```hcl
   host_project_id    = "your-host-project-id"
   service_project_id = "your-service-project-id"
   ```

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Plan the deployment:**
   ```bash
   terraform plan
   ```

5. **Apply the configuration:**
   ```bash
   terraform apply
   ```

## Application Management

The project includes containerized applications in the `apps/` directory:

### Podman Runner
Deploy a privileged container that can run podman for container-in-container scenarios:

```bash
# Build and push the image
make build-podman

# Deploy to GKE
make deploy-podman

# Access the container
make podman-shell

# View logs
make podman-logs

# Clean up
make delete-podman
```

## Common Make Targets

| Command | Description |
|---------|-------------|
| `make help` | Show all available commands |
| `make init` | Initialize Terraform |
| `make plan ENV=<env>` | Plan deployment for environment |
| `make apply ENV=<env>` | Apply deployment for environment |
| `make destroy ENV=<env>` | Destroy environment |
| `make enable-apis` | Enable required APIs |
| `make connect-gke` | Connect to deployed GKE cluster |
| `make fmt` | Format Terraform files |
| `make validate` | Validate Terraform configuration |

## Connecting to the GKE Cluster

### Using Make (Recommended)
```bash
make connect-gke
```

### Manual Connection
```bash
gcloud container clusters get-credentials [CLUSTER_NAME] \
  --region [REGION] \
  --project [SERVICE_PROJECT_ID]
```

## Project Structure

```
.
├── main.tf                      # Root configuration
├── variables.tf                 # Root variables  
├── outputs.tf                   # Root outputs
├── terraform.tfvars             # Main configuration
├── terraform.tfvars.example     # Example variables
├── apps/                        # Application deployments
│   └── podman-runner/          # Podman container app
│       ├── Dockerfile
│       ├── cloudbuild.yaml
│       └── podman-pod.yaml
└── modules/
    ├── host-vpc/               # Shared VPC module
    ├── gke-service-project/    # GKE service project module
    ├── artifact-registry/      # Docker registry module
    └── ubuntu-vm/              # Ubuntu VM module
```

## Key Features

### Host VPC Module
- Creates shared VPC with custom subnets
- Configures secondary IP ranges for GKE pods and services
- Sets up Cloud NAT for internet access
- Includes firewall rules for internal communication

### GKE Service Project Module
- Creates private GKE cluster with Workload Identity
- Configures node pools with auto-scaling
- Enables network policy and binary authorization
- Sets up proper IAM roles and service accounts

### Security Features
- Private GKE nodes (no external IPs)
- Workload Identity for secure pod authentication
- Network policies enabled
- Binary authorization for container security
- Shielded GKE nodes

## Customization

Modify the variables in `terraform.tfvars` or environment-specific files to customize:

- Network CIDR ranges
- GKE cluster configuration
- Node pool settings
- Regional deployment