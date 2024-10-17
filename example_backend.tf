# example_backend.tf
# This file provides an example configuration for the Terraform backend using Azure.
# It defines the Azure Resource Group, Storage Account, and Container to store the Terraform state file.
# This helps manage and share state between team members securely.
# Keeping the backend in a separate resource group from the project helps isolate state management from the project resources.
# Replace the placeholder values with your actual Azure resource names.
# Do not commit your real backend.tf to version control for security reasons.

# Commented out to avoid conflict with the project's configuration
# terraform {
#   backend "azurerm" {
#     resource_group_name   = "<your-resource-group>"
#     storage_account_name  = "<your-storage-account>"
#     container_name        = "<your-container-name>"
#     key                   = "example.tfstate"
#   }
# }

#################### NOTES ####################
# Instructions for setting up the Azure Storage Account for Terraform state
#
# 1. Create a Resource Group:
#    az group create --name <your-resource-group> --location <your-location>
#
# 2. Create a Storage Account:
#    az storage account create --name <your-storage-account> --resource-group <your-resource-group> --location <your-location> --sku Standard_LRS
#
# 3. Create a Storage Container:
#    az storage container create --name <your-container-name> --account-name <your-storage-account>
#
# Replace <your-resource-group>, <your-storage-account>, <your-location>, and <your-container-name> with your actual values.
