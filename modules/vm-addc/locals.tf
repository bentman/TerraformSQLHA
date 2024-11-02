# .\modules\vm-addc\locals.tf
#################### LOCALS ####################
locals {
  # Split the domain name into components based on '.' delimiter
  # This allows generating distinguished names (DN) for use with Active Directory
  split_domain    = split(".", var.domain_name)
  # Construct the Distinguished Name (DN) path for the domain, 
  # formatted as "DC=domain_component,DC=domain_component" (e.g., "DC=example,DC=com")
  dn_path         = join(",", [for dc in local.split_domain : "DC=${dc}"])
  # Define the Organizational Unit (OU) path for server objects in Active Directory,
  # placing them under "OU=Servers" within the generated DN path
  servers_ou_path = "OU=Servers,${join(",", [for dc in local.split_domain : "DC=${dc}"])}"
}