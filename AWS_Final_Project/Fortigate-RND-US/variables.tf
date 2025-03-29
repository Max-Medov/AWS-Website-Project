variable "region" {
  default = "us-east-1"
}

variable "fgt_ami" {
  default = "ami-039592fdb85a7379d"  # FortiGate AMI explicitly (payg, x86 clearly in Ohio region explicitly)
}

variable "instance_type" {
  default = "t3.small"  # clearly low cost
}

variable "az" {
  default = "us-east-1a"
}

variable "key_name" {
  default = "MyFortiKey"  # clearly insert your keypair explicitly
}

variable "aws_profile" {
  description = "AWS CLI Profile Name"
  type        = string
}
