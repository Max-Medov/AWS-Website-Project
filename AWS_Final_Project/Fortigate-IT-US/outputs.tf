output "fortigate_public_ip" {
  value = aws_eip.fgt_eip.public_ip
}

output "vpn_connection_id" {
  value = aws_vpn_connection.vpn_conn.id
}

output "vpn_gateway_id" {
  value = aws_vpn_gateway.it_vgw.id
}

output "Username" {
  value = "admin"
}

output "Password" {
  value = aws_instance.fgtvm.id
}
