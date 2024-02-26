
variable "primary_location" {
  description = "The location/region of the primary resource"
  type        = string
  default     = "West US"
}

variable "secondary_location" {
  description = "The location/region of the secondary resource"
  type        = string
  default     = "East US"
}

variable "primary_resource_group_name" {
  description = "The name of the resource group in which the primary resources will be created"
  type        = string
  default     = "myPrimaryResourceGroup"
}

variable "secondary_resource_group_name" {
  description = "The name of the resource group in which the secondary resources will be created"
  type        = string
  default     = "mySecondaryResourceGroup"
}

variable "password" {
  description = "The password for the SQL administrator"
  type        = string
  default     = "Password1234!"
}

variable "enable_dr_site" {
  description = "Whether to enable geo-replication for the SQL Server"
  type        = bool
  default     = false
}

variable "enable_elastic_pool" {
  description = "Whether to enable an elastic pool for the SQL Server"
  type        = bool
  default     = false
}

variable "enable_reporting_replica" {
  description = "Whether to enable a reporting replica for the SQL Server"
  type        = bool
  default     = false
}

variable "elastic_pool_sku_name" {
  description = "The sku name of the elastic pool"
  type        = string
  default     = "StandardPool"
}

variable "elastic_pool_sku_tier" {
  description = "The sku tier of the elastic pool"
  type        = string
  default     = "Standard"
}

variable "elastic_pool_sku_capacity" {
  description = "The capacity of the elastic pool in DTUs"
  type        = number
  default     = 50
}

variable "elastic_pool_max_size_gb" {
  description = "The maximum size of the elastic pool database in gigabytes"
  type        = number
  default     = 50
}

variable "elastic_pool_per_database_settings" {
  description = "The per-database settings for the elastic pool"
  type = object({
    min_capacity = number
    max_capacity = number
  })
  default = {
    min_capacity = 10
    max_capacity = 20
  }
}

variable "allowed_ips" {
  description = "List of IP addresses to allow to connect to the SQL Server"
  type        = list(list(string))
  default     = []
}

variable "databases" {
  description = "A list of databases to create"
  type = list(object({
    name            = string
    collation       = string
    is_elastic_pool = bool
    needs_replica   = bool
  }))
  default = []
}


