variable "service_project_id" {
  description = "The GCP service project ID where the VM will be created"
  type        = string
}

variable "host_project_id" {
  description = "The GCP host project ID for shared VPC"
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

variable "vm_name" {
  description = "Name of the VM instance"
  type        = string
  default     = "ubuntu-vm"
}

variable "machine_type" {
  description = "Machine type for the VM"
  type        = string
  default     = "e2-micro"
}

variable "subnet_name" {
  description = "Name of the subnet to use"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = ""
}