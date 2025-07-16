output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "network_self_link" {
  description = "Self link of the VPC network"
  value       = google_compute_network.vpc.self_link
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = google_compute_subnetwork.subnet.id
}

output "subnet_self_link" {
  description = "Self link of the subnet"
  value       = google_compute_subnetwork.subnet.self_link
}

output "pods_secondary_range_name" {
  description = "Name of the pods secondary range"
  value       = "pods"
}

output "services_secondary_range_name" {
  description = "Name of the services secondary range"
  value       = "services"
}

output "vm_subnet_name" {
  description = "Name of the VM subnet"
  value       = google_compute_subnetwork.vm_subnet.name
}

output "vm_subnet_id" {
  description = "ID of the VM subnet"
  value       = google_compute_subnetwork.vm_subnet.id
}