resource "aws_secretsmanager_secret" "db_secret" {
  name        = "wp-db-credentials-il-7"
  description = "DB credentials for WordPress US region"
}

resource "aws_secretsmanager_secret_version" "db_secret_value" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    engine   = "mysql"
    host     = aws_db_instance.wp_db_replica.address
    port     = aws_db_instance.wp_db_replica.port
    dbname   = var.db_name
  })
}

