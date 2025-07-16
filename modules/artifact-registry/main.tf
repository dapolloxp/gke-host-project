# Enable Artifact Registry API
resource "google_project_service" "artifactregistry_api" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy        = false
}

# Create Artifact Registry repository for Docker images
resource "google_artifact_registry_repository" "docker_repo" {
  project       = var.project_id
  location      = var.region
  repository_id = var.repository_name
  description   = "Docker repository for GKE applications"
  format        = "DOCKER"

  depends_on = [google_project_service.artifactregistry_api]
}

# IAM binding to allow GKE nodes to pull images
resource "google_artifact_registry_repository_iam_member" "gke_reader" {
  project    = var.project_id
  location   = google_artifact_registry_repository.docker_repo.location
  repository = google_artifact_registry_repository.docker_repo.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.gke_node_service_account}"

  depends_on = [google_artifact_registry_repository.docker_repo]
}