variable "project_id" {
  description = "The GCP project ID where Artifact Registry will be created"
  type        = string
}

variable "region" {
  description = "The GCP region for the Artifact Registry repository"
  type        = string
}

variable "repository_name" {
  description = "Name of the Artifact Registry repository"
  type        = string
  default     = "gke-images"
}

variable "gke_node_service_account" {
  description = "Email of the GKE node service account that needs access to the registry"
  type        = string
}