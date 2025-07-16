output "docker_repository_url" {
  description = "URL of the Docker repository"
  value       = "${google_artifact_registry_repository.docker_repo.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.name}"
}

output "docker_repository_name" {
  description = "Name of the Docker repository"
  value       = google_artifact_registry_repository.docker_repo.name
}

output "docker_repository_location" {
  description = "Location of the Docker repository"
  value       = google_artifact_registry_repository.docker_repo.location
}