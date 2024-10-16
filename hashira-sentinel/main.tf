resource "azurerm_resource_group" "secu8090" {
  name     = "hashira-sentinel-test"
  location = "Canada Central"

  tags = {
    name       = "hashira-sentinel"
    project    = "secu8090"
    billing    = "conestoga"
    managed_by = "terraform"
  }
}

# resource "azurerm_log_analytics_workspace" "secu8090" {
#   name                = "secu8090-law"
#   location            = azurerm_resource_group.secu8090.location
#   resource_group_name = azurerm_resource_group.secu8090.name
#   sku                 = "PerGB2018"
# }
#
# resource "azurerm_sentinel_log_analytics_workspace_onboarding" "secu8090" {
#   workspace_id                 = azurerm_log_analytics_workspace.secu8090.id
#   customer_managed_key_enabled = false
# }