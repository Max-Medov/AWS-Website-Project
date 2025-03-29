provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

data "aws_vpc" "existing_vpc" {
  tags = { Name = "Lovely-RD-VPC-US" }
}

data "aws_subnet" "public_subnet" {
  tags = { Name = "Public-Subnet-US-AZ1" }
}

data "aws_subnet" "private_subnet" {
  tags = { Name = "Private-Subnet-RND-US-AZ1" }
}

data "aws_route_table" "existing_private_rt" {
  filter {
    name   = "tag:Name"
    values = ["Private-RT-US"]
  }
}

# FortiGate Elastic IP
resource "aws_eip" "fgt_eip" {
  domain = "vpc"
  tags   = { Name = "FortiGate-Public-IP-US" }
}

# Security Group FortiGate
resource "aws_security_group" "fortigate_sg" {
  name        = "FortiGate-VM-SG-US"
  description = "Fortinet Recommended Ports"
  vpc_id      = data.aws_vpc.existing_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 500
    to_port     = 500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4500
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "50"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_network_interface" "fgt_public_eni" {
  subnet_id       = data.aws_subnet.public_subnet.id
  security_groups = [aws_security_group.fortigate_sg.id]
  tags            = { Name = "FortiGate-Public-ENI-US" }
}

resource "aws_network_interface" "fgt_private_eni" {
  subnet_id         = data.aws_subnet.private_subnet.id
  security_groups   = [aws_security_group.fortigate_sg.id]
  tags              = { Name = "FortiGate-Private-ENI-US" }
}

resource "aws_eip_association" "eip_assoc" {
  allocation_id        = aws_eip.fgt_eip.id
  network_interface_id = aws_network_interface.fgt_public_eni.id
}

resource "aws_instance" "fgtvm" {
  ami               = var.fgt_ami
  instance_type     = var.instance_type
  key_name          = var.key_name
  availability_zone = var.az

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.fgt_public_eni.id
  }
  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.fgt_private_eni.id
  }

  user_data = file("fgtvm.conf")
}

resource "aws_route" "vpn_route" {
  route_table_id         = data.aws_route_table.existing_private_rt.id
  destination_cidr_block = "10.1.0.0/16"
  network_interface_id   = aws_network_interface.fgt_private_eni.id
}

