module "azure_sql_db" {
  source                        = "./module.azure_sql_db"
  primary_location              = var.primary_location
  secondary_location            = var.secondary_location
  primary_resource_group_name   = var.primary_resource_group_name
  secondary_resource_group_name = var.secondary_resource_group_name
  password                      = var.password
  enable_dr_site                = var.enable_dr_site
  enable_elastic_pool           = var.enable_elastic_pool
  enable_reporting_replica      = var.enable_reporting_replica
  databases                     = var.databases
  allowed_ips                   = var.allowed_ips
  elastic_pool_sku_name         = var.elastic_pool_sku_name
  elastic_pool_sku_tier         = var.elastic_pool_sku_tier
  elastic_pool_sku_capacity     = var.elastic_pool_sku_capacity
  elastic_pool_max_size_gb      = var.elastic_pool_max_size_gb
}
