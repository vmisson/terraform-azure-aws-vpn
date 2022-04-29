#################################################################################
#
# Azure North Europe
# Address Space : 10.1.0.0/23
# ASN : 65515
#
#################################################################################
resource "azurerm_resource_group" "resource_group" {
  name     = "Azure-DC-NorthEurope"
  location = "North Europe"
}

#################################################################################
#
# Azure North Europe VNet
#
#################################################################################
resource "azurerm_virtual_network" "virtual_network" {
  name                = "azure-vnet-001"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  address_space       = ["10.1.0.0/23"]
}

resource "azurerm_subnet" "subet_gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.1.0.0/26"]
}

resource "azurerm_subnet" "subnet_workload" {
  name                 = "AzureWorkloadSubnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.1.1.0/24"]
}

#################################################################################
#
# Azure North Europe Gateway
#
#################################################################################
resource "azurerm_public_ip" "public_ip_gateway_primary" {
  name                = "azure-pip-001"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "public_ip_gateway_secondary" {
  name                = "azure-pip-002"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_virtual_network_gateway" "virtual_network_gateway" {
  name                = "azure-gateway-001"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = true
  enable_bgp    = true
  sku           = "VpnGw1"

  bgp_settings {
    asn = 65515

    peering_addresses {
      ip_configuration_name = "gw-ip1"
      apipa_addresses       = [cidrhost("169.254.21.0/30", 2), cidrhost("169.254.21.4/30", 2)]
    }

    peering_addresses {
      ip_configuration_name = "gw-ip2"
      apipa_addresses       = [cidrhost("169.254.22.0/30", 2), cidrhost("169.254.22.4/30", 2)]
    }
  }

  ip_configuration {
    name                          = "gw-ip1"
    public_ip_address_id          = azurerm_public_ip.public_ip_gateway_primary.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.subet_gateway.id
  }

  ip_configuration {
    name                          = "gw-ip2"
    public_ip_address_id          = azurerm_public_ip.public_ip_gateway_secondary.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.subet_gateway.id
  }
}

#################################################################################
#
# AWS Local Network Gateway
#
#################################################################################
resource "azurerm_local_network_gateway" "local_network_gateway_primary_tunnel1" {
  depends_on = [
    azurerm_virtual_network_gateway.virtual_network_gateway
  ]
  name                = "aws-gateway-vpn-001-tunnel1"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  gateway_address     = aws_vpn_connection.vpn_connection_primary.tunnel1_address

  bgp_settings {
    asn                 = 64512
    bgp_peering_address = cidrhost("169.254.21.0/30", 1)
  }
}

resource "azurerm_local_network_gateway" "local_network_gateway_primary_tunnel2" {
  depends_on = [
    azurerm_virtual_network_gateway.virtual_network_gateway
  ]
  name                = "aws-gateway-vpn-001-tunnel2"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  gateway_address     = aws_vpn_connection.vpn_connection_primary.tunnel2_address

  bgp_settings {
    asn                 = 64512
    bgp_peering_address = cidrhost("169.254.21.4/30", 1)
  }
}

resource "azurerm_local_network_gateway" "local_network_gateway_secondary_tunnel1" {
  depends_on = [
    azurerm_virtual_network_gateway.virtual_network_gateway
  ]
  name                = "aws-gateway-vpn-002-tunnel1"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  gateway_address     = aws_vpn_connection.vpn_connection_secondary.tunnel1_address

  bgp_settings {
    asn                 = 64512
    bgp_peering_address = cidrhost("169.254.22.0/30", 1)
  }
}

resource "azurerm_local_network_gateway" "local_network_gateway_secondary_tunnel2" {
  depends_on = [
    azurerm_virtual_network_gateway.virtual_network_gateway
  ]
  name                = "aws-gateway-vpn-002-tunnel2"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  gateway_address     = aws_vpn_connection.vpn_connection_secondary.tunnel2_address

  bgp_settings {
    asn                 = 64512
    bgp_peering_address = cidrhost("169.254.22.4/30", 1)
  }
}

#################################################################################
#
# Azure North Europe Connections
#
#################################################################################
resource "azurerm_virtual_network_gateway_connection" "aws-primary-tunnel1" {
  name                = "aws-primary-tunnel1"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.virtual_network_gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.local_network_gateway_primary_tunnel1.id

  shared_key = aws_vpn_connection.vpn_connection_primary.tunnel1_preshared_key
}

resource "azurerm_virtual_network_gateway_connection" "aws-primary-tunnel2" {
  name                = "aws-primary-tunnel2"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.virtual_network_gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.local_network_gateway_primary_tunnel2.id

  shared_key = aws_vpn_connection.vpn_connection_primary.tunnel2_preshared_key
}

resource "azurerm_virtual_network_gateway_connection" "aws-secondary-tunnel1" {
  name                = "aws-secondary-tunnel1"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.virtual_network_gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.local_network_gateway_secondary_tunnel1.id

  shared_key = aws_vpn_connection.vpn_connection_secondary.tunnel1_preshared_key
}

resource "azurerm_virtual_network_gateway_connection" "aws-secondary-tunnel2" {
  name                = "aws-secondary-tunnel2"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.virtual_network_gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.local_network_gateway_secondary_tunnel2.id

  shared_key = aws_vpn_connection.vpn_connection_secondary.tunnel2_preshared_key
}
