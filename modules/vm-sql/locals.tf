# .\modules\vm-sql\locals.tf
#################### LOCALS ####################

locals {
  # Create a flat list of SQL region-server pairs for high availability setup.
  # This list generates two entries per region (e.g., index 0 and index 1) to support
  # a primary and secondary SQL server in each region.
  region_server_pairs = flatten([
    for r in var.shortregions : [
      { region = r, index = 0 },  # Primary SQL server for the region
      { region = r, index = 1 }   # Secondary SQL server for the region
    ]
  ])
  # Generate locals for domain join parameters
  split_domain    = split(".", var.domain_name)
  dn_path         = join(",", [for dc in local.split_domain : "DC=${dc}"])
  servers_ou_path = "OU=Servers,${join(",", [for dc in local.split_domain : "DC=${dc}"])}"
}
