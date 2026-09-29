module "naming" {
  source  = "codectl/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "regions" {
  source  = "codectl/locations/azure"
  version = "~> 1.0"

  location = {
    primary = "westeurope"
  }
}

module "rg" {
  source  = "codectl/rg/azure"
  version = "~> 1.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = module.regions.location.primary.name
    }
  }
}

module "storage" {
  source  = "codectl/sa/azure"
  version = "~> 1.0"

  storage = {
    name                     = module.naming.storage_account.name_unique
    location                 = module.rg.groups.demo.location
    resource_group_name      = module.rg.groups.demo.name
    account_tier             = "Standard"
    account_replication_type = "LRS"
  }
}

module "search" {
  source  = "codectl/srch/azure"
  version = "~> 1.0"

  search_service = {
    name                = module.naming.search_service.name_unique
    resource_group_name = module.rg.groups.demo.name
    location            = module.rg.groups.demo.location
    sku                 = "standard"

    shared_private_link_services = {
      blob = {
        subresource_name   = "blob"
        target_resource_id = module.storage.account.id
        request_message    = "Please approve blob private link for search."
      }
    }
  }
}
