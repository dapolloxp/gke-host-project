# Minimal Ubuntu VM in service project using shared VPC
resource "google_compute_instance" "ubuntu_vm" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.service_project_id

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork_project = var.host_project_id
    subnetwork         = "projects/${var.host_project_id}/regions/${var.region}/subnetworks/${var.subnet_name}"
    # No external IP - using private access only
  }

  # Minimal metadata
  metadata = {
    ssh-keys = var.ssh_public_key != "" ? "ubuntu:${var.ssh_public_key}" : ""
  }

  # Use default service account with minimal scopes
  service_account {
    email  = "${data.google_project.service_project.number}-compute@developer.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  tags = ["vm"]
}

# Get service project data
data "google_project" "service_project" {
  project_id = var.service_project_id
}