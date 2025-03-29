output "fortigate_public_ip" {
  value = aws_eip.fgt_eip.public_ip
}

output "Username" {
  value = "admin"
}

output "Password" {
  value = aws_instance.fgtvm.id
}
