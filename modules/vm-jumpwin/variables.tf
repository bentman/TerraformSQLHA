#################### VARIABLES ####################
########## RESOURCE VARS 
variable "resource_group_name" {
  description = "Name of resource group for VM."
  type        = string
}

variable "location" {
  description = "Azure region for resources."
  type        = string
}

variable "shortregion" {
  description = "Short abbreviation for region used"
  type        = string
  default     = "void"
}

########## NETWORK VARS 
variable "subnet_id" {
  description = "ID of subnet for VM NIC."
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR of subnet for VM NIC."
  type        = string
}

########## VM JUMPWIN VARS 
variable "vm_size" {
  description = "Size of Windows VM."
  type        = string
  default     = "Standard_B2s_v2"
}

variable "computer_name" {
  description = "Computer name of Windows VM (HOSTNAME)."
  type        = string
  default     = "jumpwin007"
}

variable "admin_username" {
  description = "Admin username for VM."
  type        = string
  default     = "localadmin"
  sensitive   = true
}

variable "admin_password" {
  description = "Admin password for VM."
  type        = string
  default     = "P@ssw0rd!234"
  sensitive   = true
}

variable "sku" {
  description = "Image SKU for Windows VM."
  type        = string
  default     = "Standard_B2s_v2"
}

variable "vm_shutdown_hhmm" {
  description = "Daily shutdown time (HHMM format)."
  type        = string
  default     = "0000"
}

variable "vm_shutdown_tz" {
  description = "Timezone for VM shutdown."
  type        = string
  default     = "UTC"
}

########## RESOURCE TAGS 
variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default = {
    "source"      = "terraform"
    "project"     = "learning"
    "environment" = "lab"
  }
}
