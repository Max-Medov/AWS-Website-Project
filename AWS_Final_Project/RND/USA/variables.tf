variable "region" {
  type        = string
  description = "AWS IL Region"
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI Profile Name"
  type        = string
}

variable "vpc_cidr" {
  default = "10.2.0.0/16"
}

variable "az" {
  default = "us-east-1a"
}

variable "az2" {
  default = "us-east-1b"
}

variable "public_subnet_cidr" {
  default = "10.2.0.0/24"
}

variable "public_subnet_cidr_2" {
  default = "10.2.1.0/24"
}

variable "private_subnet_cidr" {
  default = "10.2.4.0/22"
}

variable "private_subnet_cidr_2" {
  default = "10.2.8.0/22"
}

variable "db_name" {
  default = "wordpress"
}

variable "db_username" {
  default = "wp_admin"
}

variable "db_password" {
  default = "Initial1!"
}

variable "wp_domain_name" {
  default = "main-wp.medov.click"
}

