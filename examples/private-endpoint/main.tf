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

module "network" {
  source  = "codectl/vnet/azure"
  version = "~> 1.0"

  vnet = {
    name                = module.naming.virtual_network.name
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
    address_space       = ["10.20.0.0/16"]

    subnets = {
      pe = {
        name                              = module.naming.subnet.name
        address_prefixes                  = ["10.20.1.0/24"]
        private_endpoint_network_policies = "Disabled"
      }
    }
  }
}

module "search" {
  source  = "codectl/srch/azure"
  version = "~> 1.0"

  search_service = {
    name                          = module.naming.search_service.name_unique
    resource_group_name           = module.rg.groups.demo.name
    location                      = module.rg.groups.demo.location
    sku                           = "standard"
    public_network_access_enabled = false
  }
}

module "private_dns" {
  source  = "codectl/pdns/azure"
  version = "~> 1.0"

  resource_group_name = module.rg.groups.demo.name

  zones = {
    private = {
      search = {
        name = "privatelink.search.windows.net"
        virtual_network_links = {
          link1 = {
            virtual_network_id = module.network.vnet.id
          }
        }
      }
    }
  }
}

module "private_endpoint" {
  source  = "codectl/pe/azure"
  version = "~> 1.0"

  resource_group_name = module.rg.groups.demo.name
  location            = module.rg.groups.demo.location

  endpoints = {
    search = {
      name      = module.naming.private_endpoint.name
      subnet_id = module.network.subnets.pe.id

      private_dns_zone_group = {
        private_dns_zone_ids = [module.private_dns.private_zones.search.id]
      }

      private_service_connection = {
        private_connection_resource_id = module.search.search_service.id
        subresource_names              = ["searchService"]
      }
    }
  }
}
