variable "region" {
  default = "us-east-2"
}

variable "fgt_ami" {
  default = "ami-05d0267b6971d9de3"  # FortiGate AMI explicitly (payg, x86 clearly in Ohio region explicitly)
}

variable "instance_type" {
  default = "t3.small"  # clearly low cost
}

variable "az" {
  default = "us-east-2a"
}

variable "key_name" {
  default = "MyFortiKey"  # clearly insert your keypair explicitly
}

variable "aws_profile" {
  description = "AWS CLI Profile Name"
  type        = string
}
