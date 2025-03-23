########################################
# rds.tf
########################################

# RDS Subnet Group (uses BOTH private subnets for multi-AZ)
resource "aws_db_subnet_group" "wp_db_subnet_group" {
  name = "wp-db-subnet-group"
  subnet_ids = [
    aws_subnet.private_subnet.id, 
    aws_subnet.private_subnet_2.id
  ]

  tags = {
    Name = "WP-DB-SubnetGroup"
  }
}

# Multi-AZ RDS MySQL
resource "aws_db_instance" "wp_db" {
  identifier              = "wp-db"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_subnet_group_name    = aws_db_subnet_group.wp_db_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  multi_az                = true
  storage_encrypted       = true
  publicly_accessible     = false
  skip_final_snapshot     = true

  backup_retention_period = 7  # 7 days of backups

  # Temporary credentials - typically replaced by Secrets Manager
  username = var.db_username
  password = var.db_password

  # If you want an initial DB created
  db_name = var.db_name

  tags = {
    Name = "WP-MySQL-DB"
  }
}

