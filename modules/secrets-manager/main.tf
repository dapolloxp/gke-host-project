# Create secrets
resource "google_secret_manager_secret" "secrets" {
  for_each = var.secrets

  project   = var.project_id
  secret_id = each.key

  labels = var.labels

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

# Create secret versions with initial values
resource "google_secret_manager_secret_version" "secret_versions" {
  for_each = var.secrets

  secret      = google_secret_manager_secret.secrets[each.key].id
  secret_data = each.value
}

# Grant GKE node service account access to secrets
resource "google_secret_manager_secret_iam_member" "gke_node_access" {
  for_each = var.secrets

  project   = var.project_id
  secret_id = google_secret_manager_secret.secrets[each.key].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.gke_node_service_account}"

  depends_on = [google_secret_manager_secret.secrets]
}

# Optional: Grant GKE workload identity access if specified
resource "google_secret_manager_secret_iam_member" "workload_identity_access" {
  for_each = var.workload_identity_service_accounts

  project   = var.project_id
  secret_id = google_secret_manager_secret.secrets[each.value.secret_name].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${each.value.service_account}"

  depends_on = [google_secret_manager_secret.secrets]
}