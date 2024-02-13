
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

variable "databases" {
  description = "A list of databases to create"
  type = list(object({
    name      = string
    collation = string
  }))
  default = []
}
