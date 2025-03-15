provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

provider "aws" {
  alias   = "secondary"
  region  = var.secondary_region
  profile = var.aws_profile
}

# Create KMS Key in Primary Region
resource "aws_kms_key" "lovely_kms" {
  description             = "Lovely company primary symmetric encryption key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  tags                    = { Name = "Lovely-KMS-Key" }
}

# Create KMS Alias for Primary Key
resource "aws_kms_alias" "kms_alias" {
  name          = "alias/lovely-kms-key"
  target_key_id = aws_kms_key.lovely_kms.id
}

# Create Primary S3 Bucket
resource "aws_s3_bucket" "lovely_bucket" {
  bucket = var.bucket_name
  tags   = { Name = "Lovely-Company-S3" }
}

# Enable Bucket Versioning
resource "aws_s3_bucket_versioning" "lovely_bucket_versioning" {
  bucket = aws_s3_bucket.lovely_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Set S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "lovely_bucket_encryption" {
  bucket = aws_s3_bucket.lovely_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.lovely_kms.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Lifecycle Policy
resource "aws_s3_bucket_lifecycle_configuration" "lovely_lifecycle" {
  bucket = aws_s3_bucket.lovely_bucket.id

  rule {
    id     = "10-days-retention"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = 10
    }
  }
}

# Create DR KMS Key in Secondary Region
resource "aws_kms_key" "lovely_kms_dr" {
  provider                 = aws.secondary
  description              = "Lovely company DR symmetric encryption key"
  deletion_window_in_days  = 10
  enable_key_rotation      = true
  tags                     = { Name = "Lovely-KMS-Key-DR" }
}

# Create KMS Alias for DR Key
resource "aws_kms_alias" "kms_alias_dr" {
  provider      = aws.secondary
  name          = "alias/lovely-kms-key-dr"
  target_key_id = aws_kms_key.lovely_kms_dr.id
}

# Create DR bucket in Secondary Region
resource "aws_s3_bucket" "lovely_bucket_dr" {
  provider = aws.secondary
  bucket   = "${var.bucket_name}-dr"
  tags     = { Name = "Lovely-Company-S3-DR" }
}

# Enable DR Bucket Versioning
resource "aws_s3_bucket_versioning" "lovely_bucket_dr_versioning" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.lovely_bucket_dr.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Set DR Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "lovely_bucket_dr_encryption" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.lovely_bucket_dr.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.lovely_kms_dr.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# IAM Role for S3 Replication
resource "aws_iam_role" "replication" {
  name = "lovely-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "s3.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM policy for S3 Replication
resource "aws_iam_policy" "replication_policy" {
  name        = "lovely-s3-replication-policy"
  description = "Permissions for S3 bucket replication."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetReplicationConfiguration",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectRetention",
          "s3:GetObjectLegalHold"
        ],
        Resource = [
          aws_s3_bucket.lovely_bucket.arn,
          "${aws_s3_bucket.lovely_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:GetObjectVersionTagging",
          "s3:ObjectOwnerOverrideToBucketOwner"
        ],
        Condition = {
          StringLikeIfExists = {
            "s3:x-amz-server-side-encryption" = ["aws:kms", "aws:kms:dsse", "AES256"]
          }
        },
        Resource = ["${aws_s3_bucket.lovely_bucket_dr.arn}/*"]
      },
      {
        Effect = "Allow",
        Action = ["kms:Decrypt"],
        Condition = {
          StringLike = { "kms:ViaService" = "s3.${var.region}.amazonaws.com" }
        },
        Resource = [aws_kms_key.lovely_kms.arn]
      },
      {
        Effect = "Allow",
        Action = ["kms:Encrypt"],
        Condition = {
          StringLike = { "kms:ViaService" = "s3.${var.secondary_region}.amazonaws.com" }
        },
        Resource = [aws_kms_key.lovely_kms_dr.arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "replication_policy_attach" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication_policy.arn
}

# Explicitly create folders
resource "aws_s3_object" "folders" {
  for_each = toset(["R&D/", "DevOps/", "IT/"])
  bucket   = aws_s3_bucket.lovely_bucket.id
  key      = each.value
}

# S3 Cross-region Replication Configuration
resource "aws_s3_bucket_replication_configuration" "replication" {
  bucket = aws_s3_bucket.lovely_bucket.id
  role   = aws_iam_role.replication.arn

  rule {
    id     = "Full-Replication"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.lovely_bucket_dr.arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = aws_kms_key.lovely_kms_dr.arn
      }
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }
  }
}

