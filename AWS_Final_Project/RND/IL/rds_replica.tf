resource "aws_db_subnet_group" "wp_db_subnet_group_il" {
  name = "wp-db-subnet-group-il"
  subnet_ids = [
    aws_subnet.private_subnet.id,
    aws_subnet.private_subnet_2.id
  ]

  tags = { Name = "WP-DB-SubnetGroup-IL" }
}

resource "aws_db_instance" "wp_db_replica" {
  identifier             = "wp-db-replica"
  replicate_source_db    = "arn:aws:rds:eu-west-1:746669228676:db:wp-db"  # Ensure your EU ARN is correct
  instance_class         = "db.t3.micro"
  db_subnet_group_name   = aws_db_subnet_group.wp_db_subnet_group_il.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false
  storage_encrypted      = true
  skip_final_snapshot    = true

  tags = { Name = "WP-DB-Replica-IL" }
}

