# .\locals.tf
#################### LOCALS ####################
locals {
  # NETWORK: Generate possible VNet peering pairs (excluding self-peering)
  vnet_peerings = {
    for pair in flatten([
      for i, src_region in var.shortregions : [
        for j, dst_region in var.shortregions : {
          name      = "${src_region}-to-${dst_region}-peering"
          src_index = i
          dst_index = j
        } if i != j
      ]
    ]) : pair.name => pair
  }
  # DOMAIN: Generate DNS Servers for the Domain (using Subnet Gateway Data)
  domain_dns_servers = [
    cidrhost(azurerm_subnet.snet_dc[0].address_prefixes[0], 5),
    cidrhost(azurerm_subnet.snet_dc[1].address_prefixes[0], 5),
    "1.1.1.1",
    "8.8.8.8"
  ]
  # Generate locals for domain join parameters
  split_domain    = split(".", var.domain_name)
  dn_path         = join(",", [for dc in local.split_domain : "DC=${dc}"])
  servers_ou_path = "OU=Servers,${join(",", [for dc in local.split_domain : "DC=${dc}"])}"
}
