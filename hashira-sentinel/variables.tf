
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
  default     = "production"
}

variable "enable_solution_microsoft_defender_for_cloud" {
  description = "Enable Microsoft Defender for Cloud Solution in Sentinel. Default is false."
  type        = bool
  default     = true
}

variable "enable_solution_threat_intelligence" {
  description = "Enable Threat Intelligence Solution in Sentinel. Default is false."
  type        = bool
  default     = true
}

variable "default_tags" {
  description = "Resources tags"
  type        = map(string)
  default = {
    name       = "hashira-sentinel"
    project    = "secu8090"
    billing    = "conestoga"
    managed_by = "terraform"
  }
}