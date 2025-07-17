terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "= 6.44.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "= 6.44.0"
    }
  }
}

provider "google" {
  project = var.host_project_id
  region  = var.region
}

provider "google-beta" {
  project = var.host_project_id
  region  = var.region
}

# Host VPC Project (Networking)
module "host_vpc" {
  source = "./modules/host-vpc"

  project_id    = var.host_project_id
  region        = var.region
  network_name  = var.network_name
  subnet_ranges = var.subnet_ranges
}

# GKE Service Project
module "gke_service_project" {
  source = "./modules/gke-service-project"

  host_project_id    = var.host_project_id
  service_project_id = var.service_project_id
  region             = var.region
  zone               = var.zone
  
  # Network configuration from host VPC
  network_name       = module.host_vpc.network_name
  subnet_name        = module.host_vpc.subnet_name
  
  # GKE configuration
  cluster_name          = var.cluster_name
  initial_node_count    = var.initial_node_count
  node_machine_type     = var.node_machine_type
  node_disk_size_gb     = var.node_disk_size_gb
  
  depends_on = [module.host_vpc]
}

# Artifact Registry
module "artifact_registry" {
  source = "./modules/artifact-registry"

  project_id               = var.service_project_id
  region                   = var.region
  repository_name          = var.artifact_registry_name
  gke_node_service_account = module.gke_service_project.node_service_account_email

  depends_on = [module.gke_service_project]
}

# Ubuntu VM
module "ubuntu_vm" {
  source = "./modules/ubuntu-vm"

  service_project_id = var.service_project_id
  host_project_id    = var.host_project_id
  region             = var.region
  zone               = var.zone
  vm_name            = var.vm_name
  machine_type       = var.vm_machine_type
  subnet_name        = module.host_vpc.vm_subnet_name
  ssh_public_key     = var.vm_ssh_public_key

  depends_on = [module.host_vpc, module.gke_service_project]
}

# Secrets Manager
module "secrets_manager" {
  source = "./modules/secrets-manager"

  project_id                        = var.service_project_id
  region                           = var.region
  secrets                          = var.secrets
  gke_node_service_account         = module.gke_service_project.node_service_account_email
  workload_identity_service_accounts = var.workload_identity_service_accounts

  depends_on = [module.gke_service_project]
}