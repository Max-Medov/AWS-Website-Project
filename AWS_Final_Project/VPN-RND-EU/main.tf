provider "aws" { 
  region = var.region 
  profile = var.aws_profile 
}

# Existing VPC explicitly referenced
data "aws_vpc" "existing_vpc" {
  tags = { Name = var.vpc_name_tag }
}

resource "aws_vpn_gateway" "rnd_vgw" {
  vpc_id = data.aws_vpc.existing_vpc.id
  tags   = { Name = "RND-VGW-EU" }
}

resource "aws_customer_gateway" "rnd_cgw" {
  bgp_asn    = var.bgp_asn
  ip_address = var.fortigate_public_ip  
  type       = "ipsec.1"
  tags       = { Name = "FortiGate-CGW" }
}

resource "aws_vpn_connection" "vpn_conn" {
  customer_gateway_id = aws_customer_gateway.rnd_cgw.id
  vpn_gateway_id      = aws_vpn_gateway.rnd_vgw.id
  type                = "ipsec.1"
  static_routes_only  = false
  tags                = { Name = "RND-to-IT-VPN" }
}

