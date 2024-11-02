# .\modules\vm-addc\variables.tf
#################### VARIABLES ####################
########## RESOURCE VARS 
variable "resource_group_names" {
  description = "Name of resource group for VM"
  type        = list(string)
}

variable "regions" {
  description = "Azure region for resources"
  type        = list(string)
}

variable "shortregions" {
  description = "Short abbreviation for region used"
  type        = list(string)
}

########## NETWORK VARS 
variable "subnet_ids" {
  description = "ID of subnet for VM NIC"
  type        = list(string)
}

variable "subnet_cidrs" {
  description = "CIDR of subnet for VM NIC"
  type        = list(string)
}

variable "domain_dns_servers" {
  description = "List of DNS servers for the network interfaces"
  type        = list(string)
  default     = []
}

########## VM ADDC VARS
variable "vm_addc_size" {
  description = "Size of VM ADDC"
  type        = string
  default     = "Standard_B2s_v2"
}

variable "domain_admin_user" {
  description = "Domain admin username (addc localadmin before domain)"
  type        = string
  default     = "domainadmin"
  sensitive   = true
}

variable "domain_admin_pswd" {
  description = "Domain admin password (addc localadmin pswd before domain)"
  type        = string
  default     = "P@ssw0rd!234"
  sensitive   = true
}

########## AD DOMAIN VARS
variable "domain_name" {
  description = "Domain name"
  type        = string
  default     = "sqlhalab.lan"
}

variable "domain_netbios_name" {
  description = "Domain NetBIOS name"
  type        = string
  default     = "SQLHALAB"
}

variable "safemode_admin_pswd" {
  description = "Domain Safe Mode password"
  type        = string
  default     = "P@ssw0rd!234"
  sensitive   = true
}

variable "temp_admin_pswd" {
  description = "Additional domain admins password for first login"
  type        = string
  default     = "P@ssw0rd!234"
  sensitive   = true
}

########## RESOURCE TAGS 
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    "source"      = "terraform"
    "project"     = "learning"
    "environment" = "lab"
  }
}
