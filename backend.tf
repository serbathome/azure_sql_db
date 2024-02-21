#  state file configuration
terraform {
  backend "azurerm" {
    resource_group_name  = "storage-accounts"
    storage_account_name = "camptfstates"
    container_name       = "tfstates"
    key                  = "dbstate.tfstate"
  }
}
