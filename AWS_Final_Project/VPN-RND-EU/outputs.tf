output "vpn_gateway_id" {
  value = aws_vpn_gateway.rnd_vgw.id
}

output "vpn_connection_id" {
  value = aws_vpn_connection.vpn_conn.id
}

output "customer_gateway_id" {
  value = aws_customer_gateway.rnd_cgw.id
}

output "vpn_tunnel1_info" {
  value = {
    tunnel1_address       = aws_vpn_connection.vpn_conn.tunnel1_address
    tunnel1_bgp_asn       = aws_vpn_connection.vpn_conn.tunnel1_bgp_asn
    tunnel1_inside_cidr   = aws_vpn_connection.vpn_conn.tunnel1_inside_cidr
    tunnel1_preshared_key = aws_vpn_connection.vpn_conn.tunnel1_preshared_key
  }
  sensitive = true
}

output "vpn_tunnel2_info" {
  value = {
    tunnel2_address       = aws_vpn_connection.vpn_conn.tunnel2_address
    tunnel2_bgp_asn       = aws_vpn_connection.vpn_conn.tunnel2_bgp_asn
    tunnel2_inside_cidr   = aws_vpn_connection.vpn_conn.tunnel2_inside_cidr
    tunnel2_preshared_key = aws_vpn_connection.vpn_conn.tunnel2_preshared_key
  }
  sensitive = true
}

