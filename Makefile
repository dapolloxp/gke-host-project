# Makefile for GCP Shared VPC Terraform Project

# Project variables
HOST_PROJECT_ID ?= networkpatterns
SERVICE_PROJECT_ID ?= networkpatterns2

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
BLUE = \033[0;34m
NC = \033[0m # No Color

.PHONY: help init plan apply destroy validate fmt check clean enable-apis connect-gke

# Default target
help: ## Show this help message
	@echo "$(BLUE)GCP Shared VPC Terraform Project$(NC)"
	@echo ""
	@echo "$(YELLOW)Available targets:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## Initialize Terraform
	@echo "$(BLUE)Initializing Terraform...$(NC)"
	terraform init

validate: ## Validate Terraform configuration
	@echo "$(BLUE)Validating Terraform configuration...$(NC)"
	terraform validate

fmt: ## Format Terraform files
	@echo "$(BLUE)Formatting Terraform files...$(NC)"
	terraform fmt -recursive

check: validate fmt ## Run validation and formatting checks
	@echo "$(GREEN)All checks passed!$(NC)"

plan: ## Plan Terraform deployment
	@echo "$(BLUE)Planning Terraform deployment...$(NC)"
	terraform plan -var-file="terraform.tfvars"

apply: ## Apply Terraform configuration
	@echo "$(BLUE)Applying Terraform configuration...$(NC)"
	terraform apply -var-file="terraform.tfvars"

destroy: ## Destroy Terraform infrastructure
	@echo "$(RED)WARNING: This will destroy all infrastructure!$(NC)"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ]
	terraform destroy -var-file="terraform.tfvars"

force-destroy: ## Force destroy with IAM cleanup (use if regular destroy fails)
	@echo "$(RED)WARNING: This will forcefully destroy all infrastructure including IAM bindings!$(NC)"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ]
	@echo "$(YELLOW)Removing lifecycle prevent_destroy from IAM bindings...$(NC)"
	terraform state rm module.gke_service_project.google_project_iam_member.gke_shared_vpc_user || true
	terraform state rm module.gke_service_project.google_project_iam_member.gke_host_service_agent || true
	terraform state rm module.gke_service_project.google_project_iam_member.compute_subnet_user || true
	@echo "$(YELLOW)Running destroy...$(NC)"
	terraform destroy -var-file="terraform.tfvars"

enable-apis: ## Enable required APIs for both projects
	@echo "$(BLUE)Enabling APIs for service project...$(NC)"
	gcloud services enable container.googleapis.com compute.googleapis.com cloudresourcemanager.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com --project=$(SERVICE_PROJECT_ID)
	@echo "$(BLUE)Enabling APIs for host project...$(NC)"
	gcloud services enable compute.googleapis.com cloudresourcemanager.googleapis.com --project=$(HOST_PROJECT_ID)
	@echo "$(GREEN)APIs enabled successfully!$(NC)"

connect-gke: ## Connect to GKE cluster (requires cluster to be deployed)
	@echo "$(BLUE)Connecting to GKE cluster...$(NC)"
	@CLUSTER_NAME=$$(terraform output -raw gke_cluster_name 2>/dev/null || echo "main-cluster"); \
	REGION=$$(terraform output -json | jq -r '.region.value // "us-central1"' 2>/dev/null || echo "us-central1"); \
	echo "Connecting to cluster: $$CLUSTER_NAME in region: $$REGION"; \
	gcloud container clusters get-credentials $$CLUSTER_NAME --region $$REGION --project $(SERVICE_PROJECT_ID)

show-outputs: ## Show Terraform outputs
	@echo "$(BLUE)Terraform Outputs:$(NC)"
	terraform output

clean: ## Clean Terraform files
	@echo "$(BLUE)Cleaning Terraform files...$(NC)"
	rm -rf .terraform/
	rm -f .terraform.lock.hcl
	rm -f terraform.tfstate*
	@echo "$(YELLOW)Note: This only cleans local files. Infrastructure remains intact.$(NC)"

setup: init enable-apis ## Setup complete environment
	@echo "$(GREEN)Setup complete!$(NC)"
	@echo "$(YELLOW)Next steps:$(NC)"
	@echo "1. Review terraform.tfvars"
	@echo "2. Run: make plan"
	@echo "3. Run: make apply"

status: ## Show current Terraform state
	@echo "$(BLUE)Terraform State:$(NC)"
	terraform state list 2>/dev/null || echo "No state found. Run 'make init' first."

security-check: ## Run basic security validation
	@echo "$(BLUE)Running security checks...$(NC)"
	@echo "Checking for sensitive data in tfvars files..."
	@grep -r "password\|secret\|key" --include="*.tfvars" . && echo "$(RED)Warning: Potential sensitive data found$(NC)" || echo "$(GREEN)No obvious sensitive data found$(NC)"
	@echo "Checking .gitignore coverage..."
	@test -f .gitignore && echo "$(GREEN)✓ .gitignore exists$(NC)" || echo "$(RED)✗ .gitignore missing$(NC)"

gcloud-auth: ## Authenticating to gcloud
	@echo "$(BLUE)Authenticating with Google Cloud...$(NC)"
	gcloud auth application-default login

build-podman: ## Build and push podman runner image to Artifact Registry
	@echo "$(BLUE)Building podman runner image with Cloud Build...$(NC)"
	gcloud builds submit . --config=apps/podman-runner/cloudbuild.yaml --project=$(SERVICE_PROJECT_ID)

deploy-podman: ## Deploy podman pod to GKE cluster
	@echo "$(BLUE)Deploying podman pod to GKE...$(NC)"
	kubectl apply -f apps/podman-runner/podman-pod.yaml

delete-podman: ## Delete podman pod from GKE cluster
	@echo "$(BLUE)Deleting podman pod from GKE...$(NC)"
	kubectl delete -f apps/podman-runner/podman-pod.yaml --ignore-not-found=true

podman-logs: ## Show logs from podman pod
	@echo "$(BLUE)Showing logs from podman pod...$(NC)"
	kubectl logs privileged-podman-pod -f

podman-shell: ## Get shell access to podman pod
	@echo "$(BLUE)Opening shell in podman pod...$(NC)"
	kubectl exec -it privileged-podman-pod -- /bin/bash