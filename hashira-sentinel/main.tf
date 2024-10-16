resource "azurerm_resource_group" "secu8090" {
  name     = "hashira-sentinel"
  location = "Canada Central"

  tags = {
    name       = "hashira-sentinel"
    project    = "secu8090"
    billing    = "conestoga"
    managed_by = "terraform"
  }
}

#log analytics workspace (azurerm_log_analytics_workspace), onboarding Sentinel (azurerm_sentinel_log_analytics_workspace_onboarding), then enabling data connectors of my choice (for starters azurerm_sentinel_data_connector_microsoft_defender_advanced_threat_protection and azurerm_sentinel_data_connector_office_365).

resource "azurerm_log_analytics_workspace" "secu8090" {
  name                = "hashira-sentinel-workspace"
  location            = azurerm_resource_group.secu8090.location
  resource_group_name = azurerm_resource_group.secu8090.name
  sku                 = "PerGB2018"
}

resource "azurerm_sentinel_log_analytics_workspace_onboarding" "secu8090" {
  workspace_id                 = azurerm_log_analytics_workspace.secu8090.id
  customer_managed_key_enabled = false
}

resource "azurerm_log_analytics_solution" "secu8090" {
  solution_name         = "AzureActivity"
  location              = azurerm_resource_group.secu8090.location
  resource_group_name   = azurerm_resource_group.secu8090.name
  workspace_resource_id = azurerm_log_analytics_workspace.secu8090.id
  workspace_name        = azurerm_log_analytics_workspace.secu8090.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/AzureActivity"
  }
}

# Enable Sentinel Training Lab Solution
module "mod_training_lab" {
  depends_on = [ azurerm_sentinel_log_analytics_workspace_onboarding.secu8090 ]
  source  = "azurenoops/overlays-arm-deployment/azurerm//modules/azure_arm_deployment/resource_group"
  version = "~> 1.0"
  count   = var.enable_sentinel && var.enable_solution_training_lab ? 1 : 0

  name                = "hashira-sentinel-training-lab-content-solution"
  resource_group_name = azurerm_resource_group.secu8090.name
  deployment_mode     = var.deployment_mode
  deploy_environment  = var.deploy_environment
  workload_name       = "solutions"

  arm_script = file("${path.module}/sentinel/training_lab.json")

  parameters_override = {
    "workspaceName" = azurerm_log_analytics_workspace.secu8090.name
    "location"      = azurerm_resource_group.secu8090.location
  }
}

variable "enable_sentinel" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any sentinel resources."
}

variable "enable_solution_training_lab" {
  description = "Enable Training Lab Solution in Sentinel. Default is false."
  type        = bool
  default     = true
}

variable "enable_sentinel_onboarding" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from onboarding the Log Analytics Workspace to Azure Sentinel."
}

variable "deployment_mode" {
  # https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-modes
  description = "The Deployment Mode for this Resource Group Template Deployment. Possible values are Complete (where resources in the Resource Group not specified in the ARM Template will be destroyed) and Incremental (where resources are additive only). This is only used in Hub Content Solutions."
  type        = string
  default     = "Incremental"

  validation {
    condition     = contains(["Incremental", "Complete"], var.deployment_mode)
    error_message = "This value must be either Incremental or Complete."
  }
}

variable "deploy_environment" {
  description = "Name of the workload's environnement (dev, test, prod, etc). This will be used to name the resources deployed by this module. default is 'dev'"
  type        = string
  default = "production"
}