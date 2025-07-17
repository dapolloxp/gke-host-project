# Applications

This directory contains containerized applications for the GKE cluster.

## Podman Runner

A privileged container that can run podman for container-in-container scenarios.

### Files:
- `podman-runner/Dockerfile` - Container image with podman installed
- `podman-runner/podman-pod.yaml` - Kubernetes pod manifest with privileged security context
- `podman-runner/cloudbuild.yaml` - Cloud Build configuration for building and pushing the image
- `podman-runner/containers.conf` - Podman container configuration
- `podman-runner/storage.conf` - Podman storage configuration

### Usage:

1. **Build and push the image:**
   ```bash
   make build-podman
   ```

2. **Deploy to GKE:**
   ```bash
   make deploy-podman
   ```

3. **Access the pod:**
   ```bash
   make podman-shell
   ```

4. **View logs:**
   ```bash
   make podman-logs
   ```

5. **Clean up:**
   ```bash
   make delete-podman
   ```

### Inside the container:
Once you're in the pod, you can use podman commands:
```bash
podman --version
podman pull alpine:latest
podman run -it alpine:latest /bin/sh
```

### Security Note:
This pod runs with privileged security context which is required for podman to function properly. Only use this in trusted environments and ensure proper RBAC controls are in place.

## Secret Manager Integration

The infrastructure includes GCP Secret Manager with the following secrets configured by default:
- `database-password`
- `api-key` 
- `jwt-secret`

### Accessing Secrets in Kubernetes

GKE nodes have IAM permissions to access secrets. Use the Secret Manager CSI driver or direct API calls:

```yaml
# Example: Using Secret Manager CSI driver
apiVersion: v1
kind: SecretProviderClass
metadata:
  name: app-secrets
spec:
  provider: gcp
  parameters:
    secrets: |
      - resourceName: "projects/networkpatterns2/secrets/database-password/versions/latest"
        path: "database-password"
```

### Managing Secrets

```bash
# List all secrets
gcloud secrets list --project=networkpatterns2

# View secret value (requires proper IAM)
gcloud secrets versions access latest --secret="database-password" --project=networkpatterns2

# Update secret value
echo "new-secret-value" | gcloud secrets versions add database-password --data-file=- --project=networkpatterns2
```