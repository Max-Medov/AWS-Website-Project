output "bucket_name" {
  value = aws_s3_bucket.lovely_bucket.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.lovely_bucket.arn
}

output "kms_key_arn" {
  value = aws_kms_key.lovely_kms.arn
}

