# Enable required APIs for the service project
resource "google_project_service" "apis" {
  for_each = toset(var.gcp_services)
  
  project = var.service_project_id
  service = each.value

  disable_dependent_services = false
}

# Attach service project to host VPC
resource "google_compute_shared_vpc_service_project" "service_project" {
  host_project    = var.host_project_id
  service_project = var.service_project_id

  depends_on = [
    google_project_service.apis
  ]
}

# Service account for GKE nodes
resource "google_service_account" "gke_nodes" {
  account_id   = "${var.cluster_name}-nodes"
  display_name = "GKE Nodes Service Account for ${var.cluster_name}"
  project      = var.service_project_id

}

# IAM bindings for the node service account
resource "google_project_iam_member" "gke_node_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer"
  ])

  project = var.service_project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# Additional permissions for pulling images from GCR/AR
resource "google_project_iam_member" "gcr_access" {
  project = var.service_project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# Get the GKE service account for the service project
data "google_project" "service_project" {
  project_id = var.service_project_id
}


# Grant GKE service account permissions on the host project for shared VPC
resource "google_project_iam_member" "gke_shared_vpc_user" {
  project = var.host_project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:service-${data.google_project.service_project.number}@container-engine-robot.iam.gserviceaccount.com"

  depends_on = [google_project_service.apis]
}

# Grant GKE service account host service agent permissions
resource "google_project_iam_member" "gke_host_service_agent" {
  project = var.host_project_id
  role    = "roles/container.hostServiceAgentUser"
  member  = "serviceAccount:service-${data.google_project.service_project.number}@container-engine-robot.iam.gserviceaccount.com"

  depends_on = [google_project_service.apis]
}

# Grant default Compute Engine service account subnet permissions on host project
resource "google_project_iam_member" "compute_subnet_user" {
  project = var.host_project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:${data.google_project.service_project.number}@cloudservices.gserviceaccount.com"
}

# Grant Cloud Build service account necessary permissions
resource "google_project_iam_member" "cloudbuild_storage_admin" {
  project = var.service_project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${data.google_project.service_project.number}@cloudbuild.gserviceaccount.com"

  depends_on = [google_project_service.apis]
}

resource "google_project_iam_member" "cloudbuild_logs_writer" {
  project = var.service_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${data.google_project.service_project.number}@cloudbuild.gserviceaccount.com"

  depends_on = [google_project_service.apis]
}

resource "google_project_iam_member" "cloudbuild_artifact_registry_writer" {
  project = var.service_project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${data.google_project.service_project.number}@cloudbuild.gserviceaccount.com"

  depends_on = [google_project_service.apis]
}

# Grant default compute service account storage access for Cloud Build
resource "google_project_iam_member" "compute_storage_admin" {
  project = var.service_project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${data.google_project.service_project.number}-compute@developer.gserviceaccount.com"

  depends_on = [google_project_service.apis]
}

# Grant Cloud Build Editor role to default compute service account
resource "google_project_iam_member" "compute_cloudbuild_editor" {
  project = var.service_project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:${data.google_project.service_project.number}-compute@developer.gserviceaccount.com"

  depends_on = [google_project_service.apis]
}

# Grant logging writer role to default compute service account
resource "google_project_iam_member" "compute_logging_writer" {
  project = var.service_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${data.google_project.service_project.number}-compute@developer.gserviceaccount.com"

  depends_on = [google_project_service.apis]
}

# Grant Artifact Registry access to default compute service account
resource "google_project_iam_member" "compute_artifact_registry_writer" {
  project = var.service_project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${data.google_project.service_project.number}-compute@developer.gserviceaccount.com"

  depends_on = [google_project_service.apis]
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  project  = var.service_project_id
  location = var.region

  # Deletion Protection

  deletion_protection = false


  # Network configuration
  network    = "projects/${var.host_project_id}/global/networks/${var.network_name}"
  subnetwork = "projects/${var.host_project_id}/regions/${var.region}/subnetworks/${var.subnet_name}"

  # IP allocation for pods and services
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"

    master_global_access_config {
      enabled = true
    }
  }

  # Master authorized networks (adjust as needed)
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "All networks"
    }
  }

  # Disable default node pool (we'll create our own)
  remove_default_node_pool = true
  initial_node_count       = 1

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.service_project_id}.svc.id.goog"
  }

  # Network policy
  network_policy {
    enabled  = false
    provider = "CALICO"
  }

  # Add-ons
  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    network_policy_config {
      disabled = false
    }

    gcp_filestore_csi_driver_config {
      enabled = false
    }

    gcs_fuse_csi_driver_config {
      enabled = false
    }

    gke_backup_agent_config {
      enabled = false
    }

    config_connector_config {
      enabled = false
    }
    
  }
  # Enable Secret Manager

  secret_manager_config {
      enabled = true
    }

  # Enable binary authorization
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  depends_on = [
    google_compute_shared_vpc_service_project.service_project,
    google_project_iam_member.gke_shared_vpc_user,
    google_project_iam_member.gke_host_service_agent,
    google_project_iam_member.compute_subnet_user
  ]
}

# Primary node pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-primary-nodes"
  project    = var.service_project_id
  location   = var.region
  cluster    = google_container_cluster.primary.name
  
  node_count = var.initial_node_count

  # Auto-scaling configuration
  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }

  # Node management
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Node configuration
  node_config {
    preemptible  = false
    machine_type = var.node_machine_type
    disk_size_gb = var.node_disk_size_gb
    disk_type    = "pd-standard"

    # Service account
    service_account = google_service_account.gke_nodes.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Security
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Labels and tags
    labels = {
      environment = "production"
      cluster     = var.cluster_name
    }

    tags = ["gke-node", var.cluster_name]

    # Node metadata
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  # Upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}