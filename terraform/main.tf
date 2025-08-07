terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.1"
    }
  }
}

provider "azurerm" {
  features {}
}

# Random pet name for unique naming
resource "random_pet" "prefix" {
  length = 2
}

# Resource group
resource "azurerm_resource_group" "main" {
  name     = "${random_pet.prefix.id}-ROY_API_RG"
  location = var.location

  tags = var.tags
}

# Budget-friendly AKS cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${random_pet.prefix.id}-weather-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${random_pet.prefix.id}-weather"
  
  # Use free tier
  sku_tier = "Free"
  
  # Minimal node pool for cost savings
  default_node_pool {
    name                = "default"
    node_count          = 1  # Start with 1 node
    vm_size             = "Standard_B2s"  # Burstable, cost-effective
    os_disk_size_gb     = 30
    os_disk_type        = "Managed"
    type                = "VirtualMachineScaleSets"
    
    # Enable autoscaling for cost optimization
    enable_auto_scaling = true
    min_count          = 1
    max_count          = 3
    
    # Use spot instances for even more savings (optional)
    # spot_max_price = -1  # Uncomment for spot instances
  }

  # Use system-assigned managed identity (free)
  identity {
    type = "SystemAssigned"
  }

  # Network settings
  network_profile {
    network_plugin = "kubenet"  # Cheaper than Azure CNI
    load_balancer_sku = "standard"
  }

  # RBAC enabled
  role_based_access_control_enabled = true

  tags = var.tags
}

# Container Registry (optional, for storing images)
resource "azurerm_container_registry" "main" {
  name                = "${replace(random_pet.prefix.id, "-", "")}weatheracr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"  # Cheapest tier
  admin_enabled       = true

  tags = var.tags
}

# Grant AKS access to ACR
resource "azurerm_role_assignment" "aks_acr" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                           = azurerm_container_registry.main.id
  skip_service_principal_aad_check = true
}
