# Terraform Backend Configuration
# This file configures the remote state backend for the GKE shared VPC project
# The actual bucket and prefix are provided via backend-config during terraform init

terraform {
  backend "gcs" {
    # Bucket and prefix are configured dynamically in CI/CD pipelines
    # For local development, you can specify these values or use terraform init -backend-config
    
    # Example for local development:
    # bucket = "your-terraform-state-bucket"
    # prefix = "dev/terraform.tfstate"
  }
}

# For local development, you can initialize with specific backend config:
# terraform init -backend-config="bucket=your-terraform-state-bucket" -backend-config="prefix=dev/terraform.tfstate"