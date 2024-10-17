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

resource "azurerm_sentinel_alert_rule_scheduled" "secu8090_suspicious" {
  name                       = "Suspicious Resource deployment Alert"
  description                = "Identifies when a rare Resource and ResourceGroup deployment occurs by a previously unseen caller."
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.secu8090.workspace_id
  display_name               = "Suspicious Resource deployment Alert"
  severity                   = "Low"
  query                      = <<QUERY
AzureActivity
| where TimeGenerated between (ago(14d) .. ago(1d))
| where OperationNameValue in~ ("Microsoft.Compute/virtualMachines/write", "Microsoft.Resources/deployments/write", "Microsoft.Resources/subscriptions/resourceGroups/write")
| summarize count() by CallerIpAddress, Caller, OperationNameValue, bin(TimeGenerated, 1d)
| join kind=rightantisemi (
    AzureActivity
    | where TimeGenerated > ago(1d)
    | where OperationNameValue in~ ("Microsoft.Compute/virtualMachines/write", "Microsoft.Resources/deployments/write", "Microsoft.Resources/subscriptions/resourceGroups/write")
    | summarize StartTimeUtc = min(TimeGenerated), EndTimeUtc = max(TimeGenerated), ActivityTimeStamp = make_set(TimeGenerated, 100), ActivityStatusValue = make_set(ActivityStatusValue, 100), CorrelationIds = make_set(CorrelationId, 100), ResourceGroups = make_set(ResourceGroup, 100), ResourceIds = make_set(_ResourceId, 100), ActivityCountByCallerIPAddress = count()
    by CallerIpAddress, Caller, OperationNameValue
) on CallerIpAddress, Caller, OperationNameValue
| extend Name = iif(Caller has '@', tostring(split(Caller, '@', 0)), "")
| extend UPNSuffix = iif(Caller has '@', tostring(split(Caller, '@', 1)), "")
| extend AadUserId = iif(Caller !has '@', Caller, "")
QUERY
}


# Enable Sentinel Training Lab Solution
module "mod_training_lab" {
  depends_on = [azurerm_sentinel_log_analytics_workspace_onboarding.secu8090]
  source     = "azurenoops/overlays-arm-deployment/azurerm//modules/azure_arm_deployment/resource_group"
  version    = "~> 1.0"
  count      = var.enable_sentinel && var.enable_solution_training_lab ? 1 : 0

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

# Enable Microsoft Defender For Cloud Solution in Sentinel
module "mod_microsoft_defender_for_cloud" {
  depends_on = [azurerm_sentinel_log_analytics_workspace_onboarding.secu8090]
  source     = "azurenoops/overlays-arm-deployment/azurerm//modules/azure_arm_deployment/resource_group"
  version    = "~> 1.0"
  count      = var.enable_sentinel && var.enable_solution_microsoft_defender_for_cloud ? 1 : 0

  name                = "hashira-microsoft-defender-cloud-solution"
  resource_group_name = azurerm_resource_group.secu8090.name
  deployment_mode     = var.deployment_mode
  deploy_environment  = var.deploy_environment
  workload_name       = "solutions"

  arm_script = file("${path.module}/sentinel/microsoft_defender_for_cloud.json")

  parameters_override = {
    "workspaceName" = azurerm_log_analytics_workspace.secu8090.name
    "location"      = azurerm_resource_group.secu8090.location
  }
}

resource "azurerm_sentinel_data_connector_microsoft_threat_intelligence" "example" {
  name                                         = "hashira-threat-intel-connector"
  log_analytics_workspace_id                   = azurerm_sentinel_log_analytics_workspace_onboarding.secu8090.workspace_id
  microsoft_emerging_threat_feed_lookback_date = "1970-01-01T00:00:00Z"
}

# Enable Threat Intelligence Solution in Sentinel
module "mod_threat_intelligence" {
  depends_on = [azurerm_sentinel_log_analytics_workspace_onboarding.secu8090]
  source     = "azurenoops/overlays-arm-deployment/azurerm//modules/azure_arm_deployment/resource_group"
  version    = "~> 1.0"
  count      = var.enable_sentinel && var.enable_solution_threat_intelligence ? 1 : 0

  name                = "deploy_threat_intelligence_solution"
  resource_group_name = azurerm_resource_group.secu8090.name
  deployment_mode     = var.deployment_mode
  deploy_environment  = var.deploy_environment
  workload_name       = "solutions"

  arm_script = file("${path.module}/sentinel/threat_intelligence.json")

  parameters_override = {
    "workspaceName" = azurerm_log_analytics_workspace.secu8090.name
    "location"      = azurerm_resource_group.secu8090.location
  }
}

# resource "azurerm_sentinel_data_connector_threat_intelligence_taxii" "secu8090" {
#   name                       = "hashira-threat-taxii-connector"
#   log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.secu8090.workspace_id
#   display_name               = "taxii2"
#   api_root_url               = "https://pulsedive.com/taxii2/api/"
#   collection_id              = "a5cffbfe-c0ff-4842-a235-cb3a7a040a37"
#   user_name                  = "taxii2"
#   password                   = "2f628278aa92e25a13db7f1d130cdf572e72806b7b753bb18caab3f297ec6c93"
# }
