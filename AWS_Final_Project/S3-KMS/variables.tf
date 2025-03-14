variable "region" {
  default = "us-east-2"
}

variable "secondary_region" {
  default = "eu-west-1"
}

variable "aws_profile" {
  description = "AWS CLI Profile Name"
  type        = string
}

variable "bucket_name" {
  default = "lovely-company-maxmedov" # Explicitly use your unique suffix explicitly
}

