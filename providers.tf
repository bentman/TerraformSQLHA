#################### PROVIDERS ####################
# Define the required providers and Terraform version
terraform {
  required_providers {
    # Provider for managing Azure resources
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    # Provider for generating random values
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    # Provider for using null resources
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    # Provider for managing TLS certificates
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    # Provider for reading http resources
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
    # Provider for managing time
    time = {
      source  = "hashicorp/time"
      version = "~> 0.0"
    }
  }
  # Specify the required Terraform version
  required_version = ">= 1.6.0"
}

# Configure the AzureRM provider with necessary credentials
provider "azurerm" {
  features {
    resource_group {
      # Prevent deletion of resource groups that contain resources
      prevent_deletion_if_contains_resources = false
    }
  }
  tenant_id       = var.arm_tenant_id
  subscription_id = var.arm_subscription_id
  client_id       = var.arm_client_id
  client_secret   = var.arm_client_secret
}
