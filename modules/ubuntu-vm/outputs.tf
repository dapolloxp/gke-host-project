output "vm_name" {
  description = "Name of the VM instance"
  value       = google_compute_instance.ubuntu_vm.name
}

output "vm_internal_ip" {
  description = "Internal IP address of the VM"
  value       = google_compute_instance.ubuntu_vm.network_interface[0].network_ip
}

output "vm_zone" {
  description = "Zone of the VM instance"
  value       = google_compute_instance.ubuntu_vm.zone
}