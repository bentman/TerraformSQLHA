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

variable "subnet_id" {
  description = "ID of subnet for VM NIC."
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR of subnet for VM NIC."
  type        = string
}

variable "vm_size" {
  description = "Size of Linux VM."
  type        = string
  default     = "Standard_B2s_v2"
}

variable "computer_name" {
  description = "Computer name of Linux VM (HOSTNAME)."
  type        = string
  default     = "jumplin008"
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
  description = "Image SKU for Linux VM."
  type        = string
  default     = "22_04-lts"
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default = {
    "source"      = "terraform"
    "project"     = "learning"
    "environment" = "lab"
  }
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
