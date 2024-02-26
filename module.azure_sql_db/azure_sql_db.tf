### Random string

resource "random_string" "random" {
  numeric = true
  upper   = false
  special = false
  lower   = true
  length  = 5
}

### allow IPs


### Pimary region

resource "azurerm_resource_group" "primary_group" {
  name     = var.primary_resource_group_name
  location = var.primary_location
}

resource "azurerm_mssql_server" "primary-sqlserver" {
  name                         = "sql-server-primary-${random_string.random.result}"
  resource_group_name          = azurerm_resource_group.primary_group.name
  location                     = azurerm_resource_group.primary_group.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = var.password
}

resource "azurerm_mssql_firewall_rule" "firewall_rule_primary" {
  count            = length(var.allowed_ips) > 0 ? length(var.allowed_ips) : 0
  name             = "firewallrule-${count.index}"
  server_id        = azurerm_mssql_server.primary-sqlserver.id
  start_ip_address = var.allowed_ips[count.index][0]
  end_ip_address   = var.allowed_ips[count.index][1]
}

resource "azurerm_mssql_elasticpool" "pool" {
  count               = var.enable_elastic_pool ? 1 : 0
  name                = "mypool"
  resource_group_name = azurerm_resource_group.primary_group.name
  location            = azurerm_resource_group.primary_group.location
  server_name         = azurerm_mssql_server.primary-sqlserver.name
  max_size_gb         = var.elastic_pool_max_size_gb
  sku {
    name     = var.elastic_pool_sku_name
    tier     = var.elastic_pool_sku_tier
    capacity = var.elastic_pool_sku_capacity
  }
  per_database_settings {
    min_capacity = var.elastic_pool_per_database_settings.min_capacity
    max_capacity = var.elastic_pool_per_database_settings.max_capacity
  }
}

resource "azurerm_mssql_database" "db" {
  count           = length(var.databases) > 0 ? length(var.databases) : 0
  name            = var.databases[count.index].name
  collation       = var.databases[count.index].collation
  server_id       = azurerm_mssql_server.primary-sqlserver.id
  elastic_pool_id = var.enable_elastic_pool && var.databases[count.index].is_elastic_pool ? azurerm_mssql_elasticpool.pool[0].id : null
}

### DR region

resource "azurerm_resource_group" "secondary_group" {
  count    = var.enable_dr_site ? 1 : 0
  name     = var.secondary_resource_group_name
  location = var.secondary_location
}

resource "azurerm_mssql_server" "secondary-sqlserver" {
  count                        = var.enable_dr_site ? 1 : 0
  name                         = "sql-server-secondary-${random_string.random.result}"
  resource_group_name          = azurerm_resource_group.secondary_group[0].name
  location                     = azurerm_resource_group.secondary_group[0].location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = var.password
}

resource "azurerm_mssql_firewall_rule" "firewall_rule_secondary" {
  count            = length(var.allowed_ips) > 0 && var.enable_dr_site ? length(var.allowed_ips) : 0
  name             = "firewallrule-${count.index}"
  server_id        = azurerm_mssql_server.secondary-sqlserver[0].id
  start_ip_address = var.allowed_ips[count.index][0]
  end_ip_address   = var.allowed_ips[count.index][1]
}

resource "azurerm_mssql_elasticpool" "secondary_pool" {
  count               = var.enable_elastic_pool && var.enable_dr_site ? 1 : 0
  name                = "mypool"
  resource_group_name = azurerm_resource_group.secondary_group[0].name
  location            = azurerm_resource_group.secondary_group[0].location
  server_name         = azurerm_mssql_server.secondary-sqlserver[0].name
  max_size_gb         = var.elastic_pool_max_size_gb
  sku {
    name     = var.elastic_pool_sku_name
    tier     = var.elastic_pool_sku_tier
    capacity = var.elastic_pool_sku_capacity
  }
  per_database_settings {
    min_capacity = var.elastic_pool_per_database_settings.min_capacity
    max_capacity = var.elastic_pool_per_database_settings.max_capacity
  }
}

### Failover group

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

### Local server with a read replica

resource "azurerm_mssql_server" "read-replica" {
  count                        = var.enable_reporting_replica ? 1 : 0
  name                         = "sql-server-replica-${random_string.random.result}"
  resource_group_name          = azurerm_resource_group.primary_group.name
  location                     = azurerm_resource_group.primary_group.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = var.password
}

resource "azurerm_mssql_firewall_rule" "firewall_rule_replica" {
  count            = length(var.allowed_ips) > 0 && var.enable_reporting_replica ? length(var.allowed_ips) : 0
  name             = "firewallrule-${count.index}"
  server_id        = azurerm_mssql_server.read-replica[0].id
  start_ip_address = var.allowed_ips[count.index][0]
  end_ip_address   = var.allowed_ips[count.index][1]
}

resource "azurerm_mssql_elasticpool" "read-replica-pool" {
  count               = var.enable_elastic_pool && var.enable_reporting_replica ? 1 : 0
  name                = "mypool-replica"
  resource_group_name = azurerm_resource_group.primary_group.name
  location            = azurerm_resource_group.primary_group.location
  server_name         = azurerm_mssql_server.read-replica[0].name
  max_size_gb         = var.elastic_pool_max_size_gb
  sku {
    name     = var.elastic_pool_sku_name
    tier     = var.elastic_pool_sku_tier
    capacity = var.elastic_pool_sku_capacity
  }
  per_database_settings {
    min_capacity = var.elastic_pool_per_database_settings.min_capacity
    max_capacity = var.elastic_pool_per_database_settings.max_capacity
  }
}

locals {
  replicas = [for db in var.databases : db if db.needs_replica == true]
}

resource "azurerm_mssql_database" "read-replica-db" {
  count                       = length(local.replicas) > 0 && var.enable_reporting_replica ? length(local.replicas) : 0
  create_mode                 = "Secondary"
  creation_source_database_id = azurerm_mssql_database.db[count.index].id
  name                        = "${var.databases[count.index].name}-replica"
  collation                   = var.databases[count.index].collation
  server_id                   = azurerm_mssql_server.read-replica[0].id
  elastic_pool_id             = var.enable_elastic_pool && local.replicas[count.index].is_elastic_pool ? azurerm_mssql_elasticpool.read-replica-pool[0].id : null
  depends_on                  = [azurerm_mssql_database.db]
}
