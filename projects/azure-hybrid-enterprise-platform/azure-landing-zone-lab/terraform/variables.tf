variable "subscription_id" {
  type        = string
  description = "Target Azure subscription ID (required by azurerm 4.x)."
}

variable "tenant_id" {
  type        = string
  description = "Microsoft Entra tenant ID."
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "canadacentral"
}

variable "name_prefix" {
  type        = string
  description = "Short prefix for resource names. Keep it unique in the subscription."
  default     = "alzlab"
}

variable "profile" {
  type        = string
  description = "Cost and completeness profile: learn (default), dev, or prod."
  default     = "learn"

  validation {
    condition     = contains(["learn", "dev", "prod"], var.profile)
    error_message = "profile must be learn, dev, or prod."
  }
}

variable "admin_source_prefix" {
  type        = string
  description = "Your public IP in CIDR (x.x.x.x/32). Used for jumpbox NSG in learn/dev when VPN is off."
}

variable "admin_username" {
  type        = string
  default     = "azadmin"
  description = "Local admin on the jump box. Password is generated into Key Vault."
}

variable "enable_firewall" {
  type        = bool
  default     = null
  description = "Override profile: deploy Azure Firewall."
}

variable "enable_vpn_gateway" {
  type        = bool
  default     = null
  description = "Override profile: deploy VPN Gateway (VpnGw*AZ, ~45 minutes)."
}

variable "enable_waf" {
  type        = bool
  default     = null
  description = "Override profile: deploy Application Gateway WAF_v2."
}

variable "enable_nat_gateway" {
  type        = bool
  default     = null
  description = "Override profile: deploy NAT Gateway on hub shared subnets."
}

variable "enable_sql" {
  type        = bool
  default     = null
  description = "Override profile: deploy private Azure SQL."
}

variable "enable_aks" {
  type        = bool
  default     = null
  description = "Override profile: deploy AKS."
}

variable "enable_management_groups" {
  type        = bool
  default     = false
  description = "Create a demo management group under Tenant Root Group. Needs MG write rights."
}

variable "enable_jumpbox" {
  type        = bool
  default     = true
  description = "Deploy the hub jump box."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Extra tags merged onto every resource."
}
