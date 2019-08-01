terraform {
    backend "azurerm" {}
}

# Configure the Azure Provider
provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=1.30.1"

  subscription_id = "1a905d91-6704-4934-820e-26d388c9f96a"
  client_id       = "949e4019-87e8-4a34-b058-fc2751f23988"
  client_secret   = "${var.aks_sp_client_secret}"
  tenant_id       = "72f988bf-86f1-41af-91ab-2d7cd011db47"
}

# Create a resource group
resource "azurerm_resource_group" "test" {
  name     = "aks-eh-dotnet-rg"
  location = "West Europe"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "test" {
  name                = "aksvnet"
  resource_group_name = "${azurerm_resource_group.test.name}"
  location            = "${azurerm_resource_group.test.location}"
  address_space       = ["172.23.114.0/23"]
}

resource "azurerm_subnet" "test" {
  name                 = "akssubnet"
  resource_group_name  = "${azurerm_resource_group.test.name}"
  virtual_network_name = "${azurerm_virtual_network.test.name}"
  address_prefix       = "172.23.114.0/24"
}

resource "azurerm_container_registry" "test" {
  name                     = "aks-eh-dotnet-acr"
  resource_group_name      = "${azurerm_resource_group.test.name}"
  location                 = "${azurerm_resource_group.test.location}"
  sku                      = "Standard"
  admin_enabled            = true
}

resource "azurerm_kubernetes_cluster" "test" {
  name                = "aks-eh-dotnet-cluster"
  location            = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"
  dns_prefix          = "cluster-tf-jt-001"

  agent_pool_profile {
    name            = "default"
    count           = 2
    vm_size         = "Standard_D1_v2"
    os_type         = "Linux"
    os_disk_size_gb = 30
    vnet_subnet_id = "${azurerm_subnet.test.id}"
  }

  service_principal {
    client_id     = "${var.aks_sp_client_id}"
    client_secret = "${var.aks_sp_client_secret}"
  }

  network_profile {
      network_plugin = "azure"
      dns_service_ip = "172.23.115.2"
      docker_bridge_cidr = "172.23.115.33/28"
      service_cidr = "172.23.115.0/27"
  }

  addon_profile {
      http_application_routing {
          enabled = true
      }
  }
}

resource "azurerm_eventhub_namespace" "test" {
  name                = "aks-eh-dotnet-ns"
  location            = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"
  sku                 = "Standard"
  capacity            = 1
  kafka_enabled       = false
}

resource "azurerm_eventhub" "test" {
  name                = "aks-eh-dotnet-eh01"
  namespace_name      = "${azurerm_eventhub_namespace.test.name}"
  resource_group_name = "${azurerm_resource_group.test.name}"
  partition_count     = 2
  message_retention   = 1
}

resource "azurerm_storage_account" "test" {
  name                     = "aksehdotnetstg"
  resource_group_name      = "${azurerm_resource_group.test.name}"
  location                 = "${azurerm_resource_group.test.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "staging"
  }
}

resource "azurerm_storage_container" "test" {
  name                  = "ehcheckpoint"
  resource_group_name   = "${azurerm_resource_group.test.name}"
  storage_account_name  = "${azurerm_storage_account.test.name}"
  container_access_type = "private"
}
