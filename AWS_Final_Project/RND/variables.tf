variable "region" {
  default = "eu-west-1"
}

variable "az" {
  default = "eu-west-1a"
}

variable "vpc_cidr" {
  default = "10.1.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.1.0.0/24"  # Public Subnet (smaller range)
}

variable "private_subnet_cidr" {
  default = "10.1.4.0/22"  # Private Subnet (1022 IPs) for 1000 instances
}

variable "aws_profile" {
  description = "AWS CLI Profile Name"
  type        = string
}

