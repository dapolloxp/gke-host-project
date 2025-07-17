variable "host_project_id" {
  description = "The GCP project ID for the host VPC"
  type        = string
}

variable "service_project_id" {
  description = "The GCP project ID for the service project"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "zone" {
  description = "The GCP zone"
  type        = string
}

variable "network_name" {
  description = "Name of the host VPC network"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet in the host VPC"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
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

variable "gcp_services" {
  description = "List of GCP services to enable"
  type        = list(string)
  default = [
    "container.googleapis.com",
    "compute.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com"
  ]
}