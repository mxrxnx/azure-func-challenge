# RESOURCE GROUP

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project_name
    managed_by  = "terraform"
  }
}

# STORAGE ACCOUNT

resource "azurerm_storage_account" "main" {
  name                     = "st${var.project_name}${var.environment}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = azurerm_resource_group.main.tags
}

# LOG ANALYTICS WORKSPACE + APPLICATION INSIGHTS

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = azurerm_resource_group.main.tags
}

resource "azurerm_application_insights" "main" {
  name                = "appi-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = azurerm_resource_group.main.tags
}

# SERVICE PLAN — CONSUMPTION (Y1)
# Y1 SKU = Consumption (Free tier)

resource "azurerm_service_plan" "main" {
  name                = "asp-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1"

  tags = azurerm_resource_group.main.tags
}

# FUNCTION APP

resource "azurerm_linux_function_app" "main" {
  name                       = "func-${var.project_name}-${var.environment}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  service_plan_id            = azurerm_service_plan.main.id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key

  site_config {
    application_stack {
      dotnet_version              = var.dotnet_version
      use_dotnet_isolated_runtime = true
    }

    ftps_state = "Disabled"
  }

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.main.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING"  = azurerm_application_insights.main.connection_string
    "FUNCTIONS_WORKER_RUNTIME"              = "dotnet-isolated"
    "WEBSITE_RUN_FROM_PACKAGE"              = "1"
  }

  tags = azurerm_resource_group.main.tags
}
# PRIVATE ENDPOINT
# The Consumption (Y1) plan does not support Private Endpoints.
# Private Endpoints require upgrading to Flex Consumption (FC1) or Premium (EP1).
#
# To enable, change the Service Plan SKU:
#   sku_name = "FC1"   (Flex Consumption — serverless with VNet support)
#   sku_name = "EP1"   (Premium — always warm, VNet support)
#
# Then uncomment the lines below.

# resource "azurerm_virtual_network" "main" {
#   name                = "vnet-${var.project_name}-${var.environment}"
#   resource_group_name = azurerm_resource_group.main.name
#   location            = azurerm_resource_group.main.location
#   address_space       = ["10.0.0.0/16"]
#
#   tags = azurerm_resource_group.main.tags
# }

# resource "azurerm_subnet" "private_endpoints" {
#   name                 = "snet-private-endpoints"
#   resource_group_name  = azurerm_resource_group.main.name
#   virtual_network_name = azurerm_virtual_network.main.name
#   address_prefixes     = ["10.0.1.0/24"]
# }

# resource "azurerm_private_dns_zone" "function" {
#   name                = "privatelink.azurewebsites.net"
#   resource_group_name = azurerm_resource_group.main.name
#
#   tags = azurerm_resource_group.main.tags
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "function" {
#   name                  = "vnet-link-${var.project_name}"
#   resource_group_name   = azurerm_resource_group.main.name
#   private_dns_zone_name = azurerm_private_dns_zone.function.name
#   virtual_network_id    = azurerm_virtual_network.main.id
#   registration_enabled  = false
# }

# resource "azurerm_private_endpoint" "function" {
#   name                = "pe-${var.project_name}-${var.environment}"
#   resource_group_name = azurerm_resource_group.main.name
#   location            = azurerm_resource_group.main.location
#   subnet_id           = azurerm_subnet.private_endpoints.id
#
#   private_service_connection {
#     name                           = "psc-${var.project_name}"
#     private_connection_resource_id = azurerm_linux_function_app.main.id
#     subresource_names              = ["sites"]
#     is_manual_connection           = false
#   }
#
#   private_dns_zone_group {
#     name                 = "dns-zone-group"
#     private_dns_zone_ids = [azurerm_private_dns_zone.function.id]
#   }
#
#   tags = azurerm_resource_group.main.tags
# }
