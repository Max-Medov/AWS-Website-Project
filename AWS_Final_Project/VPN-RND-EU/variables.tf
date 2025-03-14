variable "region" {
  default = "eu-west-1"
}

variable "vpc_name_tag" {
  default = "Lovely-RD-VPC-EU"
}

variable "private_rt_tag" {
  default = "Private-RT-EU"
}

variable "fortigate_public_ip" {
  description = "EIP of Fortigate external interface"
  type        = string
}

variable "bgp_asn" {
  default = 65001
}

variable "it_cidr_block" {
  default = "10.99.4.0/23"
}

variable "aws_profile" {
  description = "AWS CLI Profile Name"
  type        = string
}
