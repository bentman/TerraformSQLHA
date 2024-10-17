########## CREATE STORAGE FOR SQLHA ##########
# Storage account for cloud sql-witness
resource "azurerm_storage_account" "sqlha_witness" {
  count                      = length(var.regions)
  name                       = lower("${var.shortregions[count.index]}sqlwitness")
  location                   = var.regions[count.index]
  resource_group_name        = azurerm_resource_group.rg.name
  account_tier               = "Standard"
  account_replication_type   = "LRS"
  account_kind               = "StorageV2"
  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"

  tags = var.labtags
}

# Blob container for cloud sql-quorum
resource "azurerm_storage_container" "sqlha_quorum" {
  count                 = length(var.regions)
  name                  = lower("${var.shortregions[count.index]}sqlquorum")
  storage_account_name  = azurerm_storage_account.sqlha_witness[count.index].name
  container_access_type = "private"
}
