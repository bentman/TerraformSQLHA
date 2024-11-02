# .\modules\vm-sql\variables.tf
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

variable "addc_pip_address" {
  description = "The IP address of the ADDC public IP to reference"
  type        = string
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
