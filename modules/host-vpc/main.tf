# Enable shared VPC hosting on the project
resource "google_compute_shared_vpc_host_project" "host" {
  project = var.project_id
}

resource "google_compute_network" "vpc" {
  name                    = var.network_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode           = "GLOBAL"

  depends_on = [google_compute_shared_vpc_host_project.host]
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.network_name}-subnet"
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.subnet_ranges.primary

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.subnet_ranges.pods_secondary
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.subnet_ranges.services_secondary
  }

  # Enable private Google access for nodes without external IPs
  private_ip_google_access = true
}

# Additional subnet for VMs
resource "google_compute_subnetwork" "vm_subnet" {
  name          = "${var.network_name}-vm-subnet"
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.subnet_ranges.vm_subnet

  # Enable private Google access for VMs without external IPs
  private_ip_google_access = true
}

# Cloud Router for NAT Gateway
resource "google_compute_router" "router" {
  name    = "${var.network_name}-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.vpc.id
}

# NAT Gateway for outbound internet access
resource "google_compute_router_nat" "nat" {
  name                               = "${var.network_name}-nat"
  project                           = var.project_id
  router                            = google_compute_router.router.name
  region                            = var.region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall rules for GKE
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.network_name}-allow-internal"
  project = var.project_id
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    var.subnet_ranges.primary,
    var.subnet_ranges.pods_secondary,
    var.subnet_ranges.services_secondary
  ]
}

# Allow SSH access for debugging (optional)
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.network_name}-allow-ssh"
  project = var.project_id
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # Google IAP range
  target_tags   = ["ssh-allowed"]
}

# Allow IAP tunnel access to GKE nodes
resource "google_compute_firewall" "allow_iap_tunnel" {
  name    = "${var.network_name}-allow-iap-tunnel"
  project = var.project_id
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "3389", "80", "443", "8080", "8443"]
  }

  source_ranges = ["35.235.240.0/20"] # Google IAP range
  target_tags   = ["gke-node"]
}

# Allow IAP access to VMs
resource "google_compute_firewall" "allow_iap_vm" {
  name    = "${var.network_name}-allow-iap-vm"
  project = var.project_id
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  source_ranges = ["35.235.240.0/20"] # Google IAP range
  target_tags   = ["vm"]
}