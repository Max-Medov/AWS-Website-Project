########################################
# AWS Region & Profile
########################################
variable "region" {
  type        = string
  description = "AWS region where resources will be created"
  default     = "eu-west-1"
}

variable "aws_profile" {
  description = "AWS CLI Profile Name"
  type        = string
}

########################################
# VPC & Subnet CIDRs (Original)
########################################
variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.1.0.0/16"
}

# Original single-AZ approach
variable "az" {
  type        = string
  description = "Primary AZ for the first subnets"
  default     = "eu-west-1a"
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR for the first public subnet"
  default     = "10.1.0.0/24"
}

variable "private_subnet_cidr" {
  type        = string
  description = "CIDR for the first private subnet"
  default     = "10.1.4.0/24"
}

########################################
# NEW Variables for Second AZ & Subnets
########################################
variable "az2" {
  type        = string
  description = "Second Availability Zone for redundancy"
  default     = "eu-west-1b"
}

variable "public_subnet_cidr_2" {
  type        = string
  description = "CIDR for the second public subnet"
  default     = "10.1.1.0/24"
}

variable "private_subnet_cidr_2" {
  type        = string
  description = "CIDR for the second private subnet"
  default     = "10.1.5.0/24"
}

########################################
# Database & WordPress Variables
########################################
variable "db_name" {
  type    = string
  default = "wordpress"
}

variable "db_username" {
  type    = string
  default = "wp_admin"
}

variable "db_password" {
  type    = string
  default = "Initial1!"
  # This is temporary; stored in Secrets Manager as well
}

variable "wp_domain_name" {
  type        = string
  description = "Domain name for WordPress (must match the ACM certificate)"
  default     = "wp.medov.click"
}

