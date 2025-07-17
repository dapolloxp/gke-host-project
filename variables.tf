variable "host_project_id" {
  description = "The GCP project ID for the host VPC project"
  type        = string
}

variable "service_project_id" {
  description = "The GCP project ID for the service project that will contain GKE"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for zonal resources"
  type        = string
  default     = "us-central1-a"
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "shared-vpc"
}

variable "subnet_ranges" {
  description = "CIDR ranges for subnets"
  type = object({
    primary             = string
    pods_secondary      = string
    services_secondary  = string
    vm_subnet          = string
  })
  default = {
    primary             = "10.0.0.0/24"
    pods_secondary      = "10.1.0.0/16"
    services_secondary  = "10.2.0.0/16"
    vm_subnet          = "10.3.0.0/24"
  }
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "main-cluster"
}

variable "initial_node_count" {
  description = "Initial number of nodes in the node pool"
  type        = number
  default     = 1
}

variable "node_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}

variable "node_disk_size_gb" {
  description = "Disk size for GKE nodes in GB"
  type        = number
  default     = 20
}

variable "artifact_registry_name" {
  description = "Name of the Artifact Registry repository"
  type        = string
  default     = "gke-images"
}

variable "vm_name" {
  description = "Name of the Ubuntu VM"
  type        = string
  default     = "ubuntu-vm"
}

variable "vm_machine_type" {
  description = "Machine type for the Ubuntu VM"
  type        = string
  default     = "e2-micro"
}

variable "vm_ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = ""
}

variable "secrets" {
  description = "Map of secret names to their initial values"
  type        = map(string)
  default     = {}
}

variable "workload_identity_service_accounts" {
  description = "Map of workload identity service accounts that need access to specific secrets"
  type = map(object({
    service_account = string
    secret_name     = string
  }))
  default = {}
}