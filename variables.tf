# .\variables.tf
#################### SECRETS ####################
#####  Declare confidential variables here
#####  Store secret values in *.tfvars file
#####  Check .gitignore in repo for details
########## SECRETS 
variable "arm_tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  sensitive   = true
}

variable "arm_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "arm_client_id" {
  description = "Azure Client ID (Service Principal ID)"
  type        = string
  sensitive   = true
}

variable "arm_client_secret" {
  description = "Azure Client Secret (Service Principal Secret)"
  type        = string
  sensitive   = true
}

#################### ENABLE MODULES BOOL ####################
variable "enable_vm_jumpwin" {
  description = "Boolean flag to enable or disable the ./modules/vm-jumpwin"
  type        = bool
  default     = false // true -or- false 
}

variable "enable_vm_jumplin" {
  description = "Boolean flag to enable or disable the ./modules/vm-jumplin"
  type        = bool
  default     = false // true -or- false 
}

variable "enable_vm_addc" {
  description = "Boolean flag to enable or disable the ./modules/vm-addc"
  type        = bool
  default     = false // true -or- false 
}

variable "enable_vm_sql" {
  description = "Boolean flag to enable or disable the ./modules/vm-sql"
  type        = bool
  default     = false // true -or- false 
}

#################### VARIABLES ####################
########## RESOURCE VARS
variable "regions" {
  description = "Azure Regions to provision resources"
  type        = list(string)
  default     = ["westus", "eastus"] // or ["westus2", "eastus2"]
}

variable "shortregions" {
  description = "Short abbreviations for the regions"
  type        = list(string)
  default     = ["usw1", "use1"] // or ["usw2", "use2"]
}

variable "labtags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    "source"      = "terraform"
    "project"     = "learning"
    "environment" = "lab"
  }
}

########## V-NETWORK VARS
variable "address_spaces" {
  description = "CIDR address spaces for each VNET"
  type        = list(string)
  default     = ["10.1.0.0/24", "10.1.1.0/24"]
}

########## VM SHUTDOWN VARS
variable "vm_shutdown_hhmm" {
  description = "Daily shutdown time (HHMM format)"
  type        = string
  default     = "0000" // Midnight
}

variable "vm_shutdown_tz" {
  description = "Timezone for VM shutdown"
  type        = string
  default     = "Pacific Standard Time"
}

########## VM JUMPBOX VARS
variable "vm_jump_size" {
  description = "Size of VM JumpBox"
  type        = string
  default     = "Standard_B2s_v2"
}

variable "vm_jump_adminuser" {
  description = "VM JumpBox local admin username"
  type        = string
  default     = "localadmin"
  sensitive   = true
}

variable "vm_jump_adminpswd" {
  description = "VM JumpBox local admin password"
  type        = string
  default     = "P@ssw0rd!234"
  sensitive   = true
}

variable "vm_jumpwin_hostname" {
  description = "Computer name for Windows VM jumpbox"
  type        = string
  default     = "jumpwin007" // Must be unique in public DNS for region
}

variable "vm_jumpwin_sku" {
  description = "Image SKU for Windows VM jumpbox"
  type        = string
  default     = "win11-23h2-pro"
}

variable "vm_jumplin_hostname" {
  description = "Computer name for Linux VM jumpbox"
  type        = string
  default     = "jumplin008" // Must be unique in public DNS for region
}

variable "vm_jumplin_sku" {
  description = "Image SKU for Linux VM jumpbox"
  type        = string
  default     = "22_04-lts"
}

########## VM ADDC VARS
variable "vm_addc_size" {
  description = "Size of VM ADDC."
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

########## VM SQL VARS
variable "vm_sqlha_size" {
  description = "Size of SQL VM"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "sql_localadmin_user" {
  description = "VM local admin username"
  type        = string
  default     = "localadmin"
  sensitive   = true
}

variable "sql_localadmin_pswd" {
  description = "VM local admin password"
  type        = string
  default     = "P@ssw0rd!234"
  sensitive   = true
}

########## SQL VARS
variable "sql_sysadmin_user" {
  description = "SQL sysadmin username"
  type        = string
  default     = "sqladmin"
}

variable "sql_sysadmin_pswd" {
  description = "SQL sysadmin password"
  type        = string
  default     = "P@ssw0rd!234"
  sensitive   = true
}

variable "sql_svc_acct_user" {
  description = "SQL service account username"
  type        = string
  default     = "svc_mssqlserver"
}

variable "sql_svc_acct_pswd" {
  description = "SQL service account password"
  type        = string
  default     = "P@ssw0rd!234"
  sensitive   = true
}

variable "sql_disk_data" {
  description = "SQL Disk - Data"
  type        = number
  default     = 90
}

variable "sql_disk_logs" {
  description = "SQL Disk - Logs"
  type        = number
  default     = 60
}

variable "sql_disk_temp" {
  description = "SQL Disk - Temp"
  type        = number
  default     = 30
}

########## SQLHA 
variable "sql_listener" {
  description = "Name of the SQL Listener"
  type        = string
  default     = "sqllisten" // 15 character limit (like computername)
}

variable "sql_ag_name" {
  description = "Name of the SQL AG (Availability Group)"
  type        = string
  default     = "sqlhaag" // 15 character limit (like computername)
}

variable "sql_cluster_name" {
  description = "Name of the SQL cluster (WSFC)"
  type        = string
  default     = "SQLCLUSTER" // 15 character limit (like computername)
}

variable "sqldatafilepath" {
  description = "(Required) The SQL Server default data path"
  type        = string
  default     = "K:\\Data"
}

variable "sqllogfilepath" {
  description = "(Required) The SQL Server default log path"
  type        = string
  default     = "L:\\Logs"
}

variable "sqltempfilepath" {
  description = "(Required) The SQL Server default temp path"
  type        = string
  default     = "T:\\Temp"
}

variable "sql_image_offer" {
  description = "(Required) The offer type of the marketplace image cluster to be used by the SQL Virtual Machine Group. Changing this forces a new resource to be created."
  type        = string
  default     = "SQL2019-WS2022"
}

variable "sql_image_sku" {
  description = " (Required) The sku type of the marketplace image cluster to be used by the SQL Virtual Machine Group. Possible values are Developer and Enterprise."
  type        = string
  default     = "Developer"
}
