output "secret_names" {
  description = "Names of the created secrets"
  value       = [for secret in google_secret_manager_secret.secrets : secret.secret_id]
}

output "secret_ids" {
  description = "Full resource IDs of the created secrets"
  value       = { for k, secret in google_secret_manager_secret.secrets : k => secret.id }
}

output "secret_versions" {
  description = "Secret version names for the created secrets"
  value       = { for k, version in google_secret_manager_secret_version.secret_versions : k => version.name }
}

output "secret_project_id" {
  description = "Project ID where secrets are stored"
  value       = var.project_id
}