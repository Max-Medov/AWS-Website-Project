########################################
# rds_replica.tf (IL Region)
########################################

# RDS Subnet Group for IL Region Replica
resource "aws_db_subnet_group" "wp_db_subnet_group_il" {
  name = "wp-db-subnet-group-il"
  subnet_ids = [
    aws_subnet.private_subnet.id,
    aws_subnet.private_subnet_2.id
  ]

  tags = { Name = "WP-DB-SubnetGroup-IL" }
}

# RDS Read Replica Instance (IL Region)
resource "aws_db_instance" "wp_db_replica" {
  identifier              = "wp-db-replica"
  replicate_source_db     = "arn:aws:rds:eu-west-1:746669228676:db:wp-db"
  instance_class          = "db.t3.micro"
  db_subnet_group_name    = aws_db_subnet_group.wp_db_subnet_group_il.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  publicly_accessible     = false
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.rds_replica_key.arn  # This key is declared in kms.tf
  skip_final_snapshot     = true

  tags = { Name = "WP-DB-Replica-IL" }
}

