# 🚀 GCP Shared VPC with GKE Terraform Project

This comprehensive Terraform project creates a production-ready Google Cloud Platform (GCP) infrastructure implementing a **Shared VPC architecture** with enterprise-grade security and automation.

## 🏗️ What This Project Delivers

### ✅ **Infrastructure Components**
- **🌐 Host VPC Project**: Complete networking foundation with shared VPC, subnets, and security
- **⚡ Service Project**: Auto-scaling GKE cluster with private nodes and Workload Identity
- **🐳 Container Registry**: Artifact Registry for secure image storage and distribution
- **🔐 Secrets Management**: GCP Secret Manager with regional replication
- **💻 Ubuntu VM**: High-performance compute instance with SSD storage
- **🛡️ Security Hardening**: Network policies, binary authorization, and shielded nodes

### ✅ **Automation & DevOps**
- **📦 Application Deployment**: Ready-to-use containerized applications
- **🔧 Make Automation**: One-command infrastructure deployment and management  
- **🏗️ Cloud Build Integration**: Automated container image builds and deployments
- **📊 Multi-Environment Support**: Dev, staging, and production configurations
- **🔄 State Management**: Organized Terraform state with environment separation

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

### 🐳 Podman Runner Application
Deploy a privileged container with Secret Manager integration for container-in-container scenarios:

#### 📋 **Features:**
- **🔐 Secret Manager Integration**: Uses GKE's native Secret Manager CSI driver
- **🛡️ Workload Identity**: Secure service account authentication (`secret-access-sa`)
- **🐳 Container Runtime**: Privileged podman with overlay storage driver
- **📦 Resource Management**: 512Mi-2Gi memory, 250m-1 CPU allocation
- **🔑 Environment Variables**: Automatic secret injection as environment variables

#### 🚀 **Deployment Commands:**
```bash
# Build and push the image to Artifact Registry
make build-podman

# Install CSI driver and deploy to GKE (includes secret configuration)
make deploy-podman

# Bind ALL secrets to service account (recommended)
make bind-all-secrets

# OR bind individual secrets to service account
make bind-secret-access SECRET_NAME=database-password
make bind-secret-access SECRET_NAME=api-key
make bind-secret-access SECRET_NAME=jwt-secret

# Access the running container
make podman-shell

# View container logs
make podman-logs

# Clean up deployment
make delete-podman
```

#### 🔧 **Secret Management Configuration:**
- **Secret Provider**: Uses `gke` provider (GKE's native Secret Manager CSI)
- **Mount Path**: Secrets mounted at `/mnt/secrets`
- **Environment Variables**: 
  - `DATABASE_PASSWORD` from `database-password` secret
  - `API_KEY` from `api-key` secret  
  - `JWT_SECRET` from `jwt-secret` secret
- **Service Account**: `secret-access-sa` with Workload Identity integration

## 🔧 **Make Automation Commands**

This project includes a comprehensive Makefile for streamlined operations:

| 🎯 **Command** | 📝 **Description** | 🔄 **What It Does** |
|----------------|--------------------|--------------------|
| `make help` | 📋 Show all available commands | Lists all automation targets with descriptions |
| `make init` | 🚀 Initialize Terraform | Downloads providers, initializes backend, validates config |
| `make plan ENV=<env>` | 📊 Plan deployment for environment | Shows infrastructure changes before applying |
| `make apply ENV=<env>` | ✅ Apply deployment for environment | Deploys complete infrastructure with all modules |
| `make destroy ENV=<env>` | 🗑️ Destroy environment | Safely tears down all infrastructure resources |
| `make enable-apis` | ⚡ Enable required APIs | Activates all necessary GCP APIs across projects |
| `make connect-gke` | ☸️ Connect to deployed GKE cluster | Configures kubectl with cluster credentials |
| `make build-podman` | 🐳 Build podman container | Builds and pushes container image to Artifact Registry |
| `make install-secret-csi` | 🔐 Install Secret Store CSI Driver | Installs CSI driver and GCP provider components |
| `make deploy-podman` | 🚀 Deploy podman to GKE | Installs CSI driver and deploys privileged container pod |
| `make bind-secret-access SECRET_NAME=<name>` | 🔑 Bind secret access | Grants service account access to specific secrets |
| `make bind-all-secrets` | 🔐 Bind all secrets | Grants service account access to all defined secrets |
| `make podman-shell` | 💻 Access podman container | Opens interactive shell in running container |
| `make fmt` | 🎨 Format Terraform files | Formats all .tf files with consistent style |
| `make validate` | ✅ Validate Terraform configuration | Checks syntax and validates all configurations |
| `make security-check` | 🛡️ Run security analysis | Scans for security issues and compliance |

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

## 📁 Project Structure & Capabilities

```
📦 gke-host-project/
├── 📋 CLAUDE.md                     # Project documentation for Claude Code
├── ⚙️ Makefile                      # Build automation and common commands
├── 📖 README.md                     # Project documentation
├── 🔧 backend.tf                    # Terraform backend configuration
├── 🏗️ main.tf                       # Root Terraform configuration
├── 📝 variables.tf                  # Input variable definitions
├── 📤 outputs.tf                    # Output value definitions
├── ⚙️ terraform.tfvars              # Environment-specific variable values
├── 📋 terraform.tfvars.example      # Template for variable configuration
├── 🔑 yes / yes.pub                # SSH key pair files
│
├── 📦 apps/                        # 🚀 Application Deployments
│   ├── 📖 README.md
│   └── 🐳 podman-runner/           # Privileged container application
│       ├── 📄 Dockerfile           # Container image definition
│       ├── 🏗️ cloudbuild.yaml      # Cloud Build configuration
│       ├── 🔐 gcp-secrets.yaml     # Secret management configuration
│       └── ☸️ podman-pod.yaml       # Kubernetes pod specification
│
├── 🧩 modules/                     # 🔧 Reusable Terraform Modules
│   ├── 🗂️ artifact-registry/       # 🐳 Docker image repository module
│   ├── ⚡ gke-service-project/     # ☸️ GKE cluster and service project module
│   ├── 🌐 host-vpc/               # 🛡️ Shared VPC host project module
│   ├── 🔐 secrets-manager/        # 🔒 GCP Secret Manager module
│   └── 💻 ubuntu-vm/              # 🖥️ Ubuntu VM deployment module
│   (each module contains: main.tf, variables.tf, outputs.tf)
│
└── 📊 terraform-state/            # 🗃️ Terraform State Management
    ├── 🌍 environments/           # Environment-specific configurations
    │   ├── 🔧 dev/
    │   ├── 🚀 prod/
    │   └── 🧪 staging/
    ├── 🗃️ terraform.tfstate        # Current state file
    ├── 💾 terraform.tfstate.backup # State backup
    └── ⚙️ terraform.tfvars         # State-specific variables
```

### 🎯 **What Each Component Does:**

#### 🏗️ **Root Configuration**
- **main.tf**: Orchestrates all modules and defines the complete infrastructure
- **variables.tf**: Centralized input configuration with validation and defaults
- **outputs.tf**: Exposes critical infrastructure information (IPs, endpoints, etc.)
- **terraform.tfvars**: Environment-specific settings (project IDs, regions, etc.)

#### 🧩 **Terraform Modules** (Reusable Infrastructure Components)
- **🌐 host-vpc/**: Creates shared VPC with subnets, NAT gateway, and firewall rules
- **⚡ gke-service-project/**: Deploys private GKE cluster with auto-scaling and security
- **🐳 artifact-registry/**: Sets up Docker image repository with IAM permissions
- **🔐 secrets-manager/**: Manages secure credential storage with regional replication
- **💻 ubuntu-vm/**: Provisions high-performance Ubuntu VM with SSD storage

#### 📦 **Application Layer**
- **🐳 podman-runner/**: Privileged container with Secret Manager CSI integration
  - **Secret Provider**: GKE native Secret Manager CSI driver (`gke` provider)
  - **Service Account**: `secret-access-sa` with Workload Identity
  - **Secrets**: Database password, API key, JWT secret mounted and injected as env vars
  - **Runtime**: Podman with overlay storage driver and full privileges
- **🏗️ Cloud Build**: Automated container image builds and deployments to Artifact Registry
- **☸️ Kubernetes**: Pod specifications with CSI volume mounts and secret injection

#### 📊 **State Management**
- **🌍 Multi-Environment**: Separate configurations for dev, staging, and production
- **🗃️ State Files**: Centralized Terraform state with automatic backups
- **🔄 Version Control**: Environment-specific variable management

## 🎯 Key Capabilities & Features

### 🌐 **Host VPC Module** - Network Foundation
- ✅ **Shared VPC Architecture**: Centralized network management across projects
- ✅ **Custom Subnets**: Dedicated GKE subnet (with secondary ranges) + VM subnet
- ✅ **IP Address Management**: Automatic CIDR allocation for nodes, pods, and services
- ✅ **Internet Access**: Cloud NAT gateway for private node internet connectivity
- ✅ **Security Rules**: Firewall rules for internal communication and IAP access
- ✅ **Global Routing**: Optimized network performance across regions

### ⚡ **GKE Service Project Module** - Container Orchestration
- ✅ **Centralized API Management**: Single source of truth for all GCP API enablement
- ✅ **Private GKE Cluster**: Secure cluster with no external IPs on nodes
- ✅ **Workload Identity**: Secure pod-to-GCP service authentication
- ✅ **Auto-Scaling Node Pools**: Dynamic scaling from 1-5 nodes based on demand
- ✅ **Security Hardening**: Network policies, binary authorization, shielded nodes
- ✅ **Cross-Project IAM**: Comprehensive permissions for shared VPC access

### 🐳 **Artifact Registry Module** - Container Image Management
- ✅ **Docker Repository**: Secure, private container image storage
- ✅ **Cloud Build Integration**: Automated image builds and deployments
- ✅ **IAM Security**: Granular access control for GKE nodes and build processes
- ✅ **Regional Replication**: High availability and performance optimization

### 🔐 **Secrets Manager Module** - Secure Credential Storage
- ✅ **Regional Replication**: High availability secret storage
- ✅ **GKE Integration**: Seamless secret access from Kubernetes pods
- ✅ **Workload Identity**: Secure service account authentication
- ✅ **Version Management**: Automatic secret versioning and rotation support

### 💻 **Ubuntu VM Module** - High-Performance Compute
- ✅ **High-Spec VM**: 4 vCPU, 16GB RAM, 50GB SSD storage
- ✅ **Shared VPC Integration**: Connected to dedicated VM subnet
- ✅ **IAP Access**: Secure access without external IPs
- ✅ **Custom Configuration**: Optimized for development and testing workloads

### 🛡️ **Enterprise Security Features**
- ✅ **Zero External IPs**: All nodes and VMs use private IPs only
- ✅ **Workload Identity**: Secure pod authentication without service account keys
- ✅ **Network Policies**: Granular pod-to-pod communication control
- ✅ **Binary Authorization**: Container image security and compliance
- ✅ **Shielded Nodes**: Secure boot and integrity monitoring
- ✅ **IAP Integration**: Secure access without VPN requirements

## Customization

Modify the variables in `terraform.tfvars` to customize:

- **Network CIDR ranges** for GKE and VM subnets
- **GKE cluster configuration** (node count, machine types, disk sizes)
- **VM specifications** (machine type, disk size)
- **Secrets** (add/remove secrets as needed)
- **Regional deployment** settings
- **Artifact Registry** repository names

### API Management
All GCP APIs are managed centrally in the GKE Service Project module using a consolidated `for_each` resource. This ensures:
- Single source of truth for API enablement
- Consistent configuration across all services
- Proper dependency management between modules