provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

provider "aws" {
  alias   = "secondary"
  region  = var.secondary_region
  profile = var.aws_profile
}

# Explicitly create KMS Key
resource "aws_kms_key" "lovely_kms" {
  description             = "Lovely company symmetric encryption key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  tags                    = { Name = "Lovely-KMS-Key" }
}

# Explicitly create KMS Alias
resource "aws_kms_alias" "kms_alias" {
  name          = "alias/lovely-kms-key"
  target_key_id = aws_kms_key.lovely_kms.id
}

# Explicitly create S3 Bucket
resource "aws_s3_bucket" "lovely_bucket" {
  bucket = var.bucket_name

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.lovely_kms.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = { Name = "Lovely-Company-S3" }
}

# Enable S3 Bucket Versioning (Fix: Separate resource for versioning)
resource "aws_s3_bucket_versioning" "lovely_bucket_versioning" {
  bucket = aws_s3_bucket.lovely_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Use aws_s3_bucket_lifecycle_configuration instead of lifecycle_rule (Fix: Added filter)
resource "aws_s3_bucket_lifecycle_configuration" "lovely_lifecycle" {
  bucket = aws_s3_bucket.lovely_bucket.id

  rule {
    id     = "10-days-Retention"
    status = "Enabled"

    filter { # ✅ Fix: Required filter
      prefix = "" # Apply to all objects, or set a folder like "logs/"
    }

    noncurrent_version_expiration {
      noncurrent_days = 10
    }
  }
}

# Explicitly create folder structure (Fix: Used aws_s3_object instead of deprecated aws_s3_bucket_object)
resource "aws_s3_object" "folders" {
  for_each = toset(["R&D/", "DevOps/", "IT/"])

  bucket = aws_s3_bucket.lovely_bucket.id
  key    = each.value
}

# Explicitly enable S3 bucket replication for DR
resource "aws_s3_bucket_replication_configuration" "replication" {
  depends_on = [aws_s3_bucket_versioning.lovely_bucket_versioning]

  bucket = aws_s3_bucket.lovely_bucket.id
  role   = aws_iam_role.replication.arn

  rule {
    id     = "Cross-Region-Replication"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.lovely_bucket_dr.arn
      storage_class = "STANDARD"
    }
  }
}

# Secondary S3 Bucket for DR (Fix: Used provider alias instead of region)
resource "aws_s3_bucket" "lovely_bucket_dr" {
  provider = aws.secondary
  bucket   = "${var.bucket_name}-dr"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.lovely_kms.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = { Name = "Lovely-Company-S3-DR" }
}

# Enable Versioning for DR bucket
resource "aws_s3_bucket_versioning" "lovely_bucket_dr_versioning" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.lovely_bucket_dr.id

  versioning_configuration {
    status = "Enabled"
  }
}

# IAM Role for Replication
resource "aws_iam_role" "replication" {
  name = "lovely-s3-replication-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_policy_attachment" "replication_policy" {
  name       = "lovely-s3-replication-policy-attachment"
  roles      = [aws_iam_role.replication.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

