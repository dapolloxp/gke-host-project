output "host_vpc_network_name" {
  description = "Name of the host VPC network"
  value       = module.host_vpc.network_name
}

output "host_vpc_network_id" {
  description = "ID of the host VPC network"
  value       = module.host_vpc.network_id
}

output "host_vpc_subnet_name" {
  description = "Name of the host VPC subnet"
  value       = module.host_vpc.subnet_name
}

output "gke_cluster_name" {
  description = "Name of the GKE cluster"
  value       = module.gke_service_project.cluster_name
}

output "gke_cluster_endpoint" {
  description = "Endpoint of the GKE cluster"
  value       = module.gke_service_project.cluster_endpoint
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "CA certificate of the GKE cluster"
  value       = module.gke_service_project.cluster_ca_certificate
  sensitive   = true
}

output "artifact_registry_docker_url" {
  description = "URL of the Docker Artifact Registry repository"
  value       = module.artifact_registry.docker_repository_url
}

output "artifact_registry_docker_name" {
  description = "Name of the Docker Artifact Registry repository"
  value       = module.artifact_registry.docker_repository_name
}

output "ubuntu_vm_name" {
  description = "Name of the Ubuntu VM"
  value       = module.ubuntu_vm.vm_name
}

output "ubuntu_vm_internal_ip" {
  description = "Internal IP address of the Ubuntu VM"
  value       = module.ubuntu_vm.vm_internal_ip
}

output "secrets_manager_secret_names" {
  description = "Names of the created secrets"
  value       = module.secrets_manager.secret_names
}

output "secrets_manager_secret_ids" {
  description = "Full resource IDs of the created secrets"
  value       = module.secrets_manager.secret_ids
}