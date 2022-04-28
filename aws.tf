#################################################################################
#
# AWS EU West 1
# Address Space : 10.2.0.0/23
# ASN : 64512
#
#################################################################################

#################################################################################
#
# AWS EU West 1 VPC
#
#################################################################################
resource "aws_vpc" "vpc" {
  cidr_block = "10.2.0.0/23"

  tags = {
    Name = "aws-vpc-001"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.2.0.0/24"

  tags = {
    Name = "AWSWorkloadSubnet"
  }
}

#################################################################################
#
# AWS EU West 1 Gateway
#
#################################################################################
resource "aws_vpn_gateway" "vpn_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "aws-gateway-001"
  }
}

resource "aws_vpn_gateway_route_propagation" "gateway_route_propagation" {
  vpn_gateway_id = aws_vpn_gateway.vpn_gateway.id
  route_table_id = aws_vpc.vpc.main_route_table_id
}

#################################################################################
#
# Azure Local Network Gateway
#
#################################################################################
resource "aws_customer_gateway" "customer_gateway_primary" {
  bgp_asn    = 65515
  ip_address = azurerm_public_ip.public_ip_gateway_primary.ip_address
  type       = "ipsec.1"

  tags = {
    Name = "azure-gateway-001-primary"
  }
}

resource "aws_customer_gateway" "customer_gateway_secondary" {
  bgp_asn    = 65515
  ip_address = azurerm_public_ip.public_ip_gateway_secondary.ip_address
  type       = "ipsec.1"

  tags = {
    Name = "azure-gateway-001-secondary"
  }
}

#################################################################################
#
# AWS EU West 1 Connections
#
#################################################################################
resource "aws_vpn_connection" "vpn_connection_primary" {
  vpn_gateway_id      = aws_vpn_gateway.vpn_gateway.id
  customer_gateway_id = aws_customer_gateway.customer_gateway_primary.id
  type                = "ipsec.1"

  tunnel1_inside_cidr = "169.254.21.0/30"
  tunnel2_inside_cidr = "169.254.21.4/30"

  tags = {
    Name = "azure-vpn-001-primary"
  }
}

resource "aws_vpn_connection" "vpn_connection_secondary" {
  vpn_gateway_id      = aws_vpn_gateway.vpn_gateway.id
  customer_gateway_id = aws_customer_gateway.customer_gateway_secondary.id
  type                = "ipsec.1"

  tunnel1_inside_cidr = "169.254.22.0/30"
  tunnel2_inside_cidr = "169.254.22.4/30"

  tags = {
    Name = "azure-vpn-001-secondary"
  }
}