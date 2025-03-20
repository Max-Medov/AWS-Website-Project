##########################################################
# secrets_manager.tf
#
# Place in RND/ folder
##########################################################

resource "aws_secretsmanager_secret" "db_secret" {
  name        = "wp-db-credentials-v2"
  description = "Stores DB credentials for WordPress"
}

resource "aws_secretsmanager_secret_version" "db_secret_value" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = "wp_admin"
    password = "Initial1!"
    engine   = "mysql"
    host     = aws_db_instance.wp_db.address
    port     = aws_db_instance.wp_db.port
    dbname   = "wordpress"
  })
}

