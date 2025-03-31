variable "region" {
  default = "us-east-2"
}

variable "aws_profile" {
  description = "AWS CLI Profile Name"
  type        = string
}

variable "bucket_name" {
  default = "lovely-company-files-maxmedov"
}

variable "sns_email" {
  default = "maximedov90@gmail.com"
}

variable "alb_domain_name" {
  type        = string
  description = "Domain name for the ALB to create ACM certificate"
}

variable "kms_key_arn" {
  description = "KMS key ARN for S3 encryption"
  type        = string
}
