variable "region" {
  default = "us-east-2"
}

variable "az_a" {
  default = "us-east-2a"
}

variable "az_b" {
  default = "us-east-2b"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.0.0.0/24"  
}

variable "public_subnet_cidr_2" {
  default = "10.0.1.0/24"  
}

variable "private_subnet_cidr" {
  default = "10.0.4.0/23"  # Private Subnet (510 IPs) for 500 instances
}

variable "private_subnet_cidr_2" {
  default = "10.0.6.0/23"  # Private Subnet (510 IPs) for 500 instances
}

variable "aws_profile" {
  description = "AWS CLI Profile Name"
  type        = string
}

