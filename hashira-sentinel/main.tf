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

