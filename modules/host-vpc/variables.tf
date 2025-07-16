variable "project_id" {
  description = "The GCP project ID for the host VPC"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnet_ranges" {
  description = "CIDR ranges for subnets"
  type = object({
    primary             = string
    pods_secondary      = string
    services_secondary  = string
    vm_subnet          = string
  })
}

