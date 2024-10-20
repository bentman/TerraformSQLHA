#################### VARIABLES ####################
########## SECRETS VARIABLES 
#####  Declare confidential variables here
#####  Store secret values in *.tfvars file
#####  Check .gitignore in repo for details
########## SECRETS VARIABLES 
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

########## RESOURCE VARS 
variable "regions" {
  description = "Azure Regions to provision resources"
  default     = ["westus", "eastus"]
}

variable "shortregions" {
  description = "Region short abbreviation to use for Resource names"
  default     = ["usw", "use"]
}

variable "labtags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default = {
    "source"      = "terraform"
    "project"     = "learning"
    "environment" = "lab"
  }
}

########## NETWORK VARS 
variable "address_spaces" {
  description = "vNet Address Space with CIDR notation"
  default     = ["10.1.0.0/24", "10.1.1.0/24"]
}

########## VM VARIABLES
variable "vm_addc_size" {
  description = "value"
  default     = "Standard_D2s_v3"
}

variable "vm_sqlha_size" {
  description = "The size of the Virtual Machine(s) type."
  type        = string
  default     = "Standard_D2s_v3"
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

variable "vm_shutdown_hhmm" {
  description = "Time for VM Shutdown HHMM"
  type        = string
  default     = "0000" // midnight ;-)
}

variable "vm_shutdown_tz" {
  description = "Time Zone for VM Shutdown"
  type        = string
  default     = "Pacific Standard Time"
}

########## ADDC VARIABLES
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

variable "domain_admin_user" {
  description = "Domain admin username"
  type        = string
  default     = "domainadmin"
  sensitive   = true
}

variable "domain_admin_pswd" {
  description = "Domain admin password"
  type        = string
  default     = "P@ssw0rd!234"
  sensitive   = true
}

variable "temp_admin_pswd" {
  description = "Domain admins added temp password (to be changed first login)"
  type        = string
  default     = "P@ssw0rd!234"
  sensitive   = true
}

variable "safemode_admin_pswd" {
  description = "Domain Safe Mode password"
  type        = string
  default     = "P@ssw0rd!234"
  sensitive   = true
}

########## SQLHA VARIABLES
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

########## sqlha 
variable "sql_listener" {
  description = "Name of the SQL Listener"
  type        = string
  default     = "sqllisten"
}

variable "sql_ag_name" {
  description = "Name of the SQL AG (Availability Group)"
  type        = string
  default     = "sqlag"
}

variable "sql_cluster_name" {
  description = "Name of the SQL cluster"
  type        = string
  default     = "sqlcluster"
}

variable "sqldatafilepath" {
  type        = string
  default     = "K:\\Data"
  description = "(Required) The SQL Server default data path"
}

variable "sqllogfilepath" {
  type        = string
  default     = "L:\\Logs"
  description = "(Required) The SQL Server default log path"
}

variable "sqltempfilepath" {
  type        = string
  default     = "T:\\Temp"
  description = "(Required) The SQL Server default temp path"
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
