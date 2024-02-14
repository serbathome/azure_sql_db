# Pimary region

resource "azurerm_resource_group" "primary_group" {
  name     = var.primary_resource_group_name
  location = var.primary_location
}

resource "azurerm_mssql_server" "primary-sqlserver" {
  name                         = "myserver-92348612"
  resource_group_name          = azurerm_resource_group.primary_group.name
  location                     = azurerm_resource_group.primary_group.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = var.password
}

resource "azurerm_mssql_elasticpool" "pool" {
  count               = var.enable_elastic_pool ? 1 : 0
  name                = "mypool"
  resource_group_name = azurerm_resource_group.primary_group.name
  location            = azurerm_resource_group.primary_group.location
  server_name         = azurerm_mssql_server.primary-sqlserver.name
  max_size_gb         = 50
  sku {
    name     = "StandardPool"
    tier     = "Standard"
    capacity = 50
  }
  per_database_settings {
    min_capacity = 10
    max_capacity = 20
  }
}

resource "azurerm_mssql_database" "db" {
  count           = length(var.databases) > 0 ? length(var.databases) : 0
  name            = var.databases[count.index].name
  collation       = var.databases[count.index].collation
  server_id       = azurerm_mssql_server.primary-sqlserver.id
  elastic_pool_id = var.enable_elastic_pool && var.databases[count.index].is_elastic_pool ? azurerm_mssql_elasticpool.pool[0].id : null
}

# DR region

resource "azurerm_resource_group" "secondary_group" {
  count    = var.enable_dr_site ? 1 : 0
  name     = var.secondary_resource_group_name
  location = var.secondary_location
}

resource "azurerm_mssql_server" "secondary-sqlserver" {
  count                        = var.enable_dr_site ? 1 : 0
  name                         = "myserver-92348613"
  resource_group_name          = azurerm_resource_group.secondary_group[0].name
  location                     = azurerm_resource_group.secondary_group[0].location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = var.password
}

resource "azurerm_mssql_elasticpool" "secondary_pool" {
  count               = var.enable_elastic_pool && var.enable_dr_site ? 1 : 0
  name                = "mypool"
  resource_group_name = azurerm_resource_group.secondary_group[0].name
  location            = azurerm_resource_group.secondary_group[0].location
  server_name         = azurerm_mssql_server.secondary-sqlserver[0].name
  max_size_gb         = 50
  sku {
    name     = "StandardPool"
    tier     = "Standard"
    capacity = 50
  }
  per_database_settings {
    min_capacity = 10
    max_capacity = 20
  }
}

# Failover group

resource "azurerm_mssql_failover_group" "failover" {
  count     = var.enable_dr_site ? 1 : 0
  name      = "myfailovergroup"
  server_id = azurerm_mssql_server.primary-sqlserver.id
  partner_server {
    id = azurerm_mssql_server.secondary-sqlserver[0].id
  }
  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = 60
  }
  databases = [for db in azurerm_mssql_database.db : db.id]
}

# Local server with a read replica
resource "azurerm_mssql_server" "read-replica" {
  count                        = var.enable_reporting_replica ? 1 : 0
  name                         = "myserver-92348614"
  resource_group_name          = azurerm_resource_group.primary_group.name
  location                     = azurerm_resource_group.primary_group.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = var.password

}

resource "azurerm_mssql_elasticpool" "read-replica-pool" {
  count               = var.enable_elastic_pool && var.enable_reporting_replica ? 1 : 0
  name                = "mypool-replica"
  resource_group_name = azurerm_resource_group.primary_group.name
  location            = azurerm_resource_group.primary_group.location
  server_name         = azurerm_mssql_server.read-replica[0].name
  max_size_gb         = 50
  sku {
    name     = "StandardPool"
    tier     = "Standard"
    capacity = 50
  }
  per_database_settings {
    min_capacity = 10
    max_capacity = 20
  }
}

resource "azurerm_mssql_database" "read-replica-db" {
  count                       = length(var.databases) > 0 && var.enable_reporting_replica ? length(var.databases) : 0
  create_mode                 = "Secondary"
  creation_source_database_id = azurerm_mssql_database.db[count.index].id
  name                        = "${var.databases[count.index].name}-replica"
  collation                   = var.databases[count.index].collation
  server_id                   = azurerm_mssql_server.read-replica[0].id
  elastic_pool_id             = var.enable_elastic_pool && var.databases[count.index].is_elastic_pool ? azurerm_mssql_elasticpool.read-replica-pool[0].id : null
  depends_on                  = [azurerm_mssql_database.db]
}
