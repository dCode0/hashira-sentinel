terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }

  # Update this block with the location of your terraform state file
  backend "azurerm" {
    resource_group_name  = "hashira-sentinel"
    storage_account_name = "hashirasecurity"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    # use_oidc             = true
  }
}

provider "azurerm" {
  features {}
}