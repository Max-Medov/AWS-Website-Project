resource "aws_kms_key" "rds_replica_key" {
  description         = "KMS Key for RDS Replica Encryption (US Region)"
  deletion_window_in_days = 10
  enable_key_rotation = true
}

resource "aws_kms_alias" "rds_replica_key_alias" {
  name          = "alias/wp-rds-replica-key"
  target_key_id = aws_kms_key.rds_replica_key.id
}

