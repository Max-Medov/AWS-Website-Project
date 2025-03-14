variable "region" {
  default = "us-east-2"
}

variable "az" {
  default = "us-east-2a"
}

variable "vpc_cidr" {
  default = "10.99.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.99.0.0/24"  # Public Subnet (smaller range)
}

variable "private_subnet_cidr" {
  default = "10.99.4.0/23"  # Private Subnet (510 IPs) for 500 instances
}

variable "aws_profile" {
  description = "AWS CLI Profile Name"
  type        = string
}

