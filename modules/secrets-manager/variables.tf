variable "project_id" {
  description = "The GCP project ID where Secret Manager will be created"
  type        = string
}

variable "region" {
  description = "The GCP region for secret replication"
  type        = string
}

variable "secrets" {
  description = "Map of secret names to their initial values"
  type        = map(string)
  default     = {}
}

variable "gke_node_service_account" {
  description = "Email of the GKE node service account that needs access to secrets"
  type        = string
}

variable "workload_identity_service_accounts" {
  description = "Map of workload identity service accounts that need access to specific secrets"
  type = map(object({
    service_account = string
    secret_name     = string
  }))
  default = {}
}

variable "labels" {
  description = "Labels to apply to secrets"
  type        = map(string)
  default = {
    managed-by = "terraform"
  }
}