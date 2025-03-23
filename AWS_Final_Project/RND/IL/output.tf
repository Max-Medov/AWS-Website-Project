output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_id" {
  value = aws_subnet.public_subnet.id
}

output "private_subnet_id" {
  value = aws_subnet.private_subnet.id
}

output "nat_gateway_ip" {
  value = aws_eip.nat_eip.public_ip
}

output "alb_dns_name" {
  value = aws_lb.wp_alb.dns_name
}

# IL Replica Endpoint (Corrected)
output "il_rds_replica_endpoint" {
  value = aws_db_instance.wp_db_replica.address
}

output "ecs_service_name" {
  value = aws_ecs_service.wp_service.name
}

