provider "aws" {
  region = var.region
  profile = var.aws_profile
}

data "aws_vpc" "existing_vpc" {
  tags = { Name = "Lovely-IT-DevOps-VPC-US" }
}

data "aws_subnet" "public_subnet" {
  tags = { Name = "Public-Subnet-US" }
}

data "aws_subnet" "private_subnet" {
  tags = { Name = "Private-Subnet-US" }
}

data "aws_route_table" "existing_private_rt" {
  filter {
    name   = "tag:Name"
    values = ["Private-RT-US"]
  }
}

data "aws_route_table" "existing_public_rt" {
  filter {
    name   = "tag:Name"
    values = ["Public-RT-US"]
  }
}


# FortiGate Elastic IP
resource "aws_eip" "fgt_eip" {
  domain = "vpc"
  tags   = { Name = "FortiGate-Public-IP" }
}

# Security Group for FortiGate VM
resource "aws_security_group" "fortigate_sg" {
  name        = "FortiGate-VM-SG"
  description = "Security Group with Fortinet recommended ports"
  vpc_id      = data.aws_vpc.existing_vpc.id

  ingress {
    description = "HTTPS GUI"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH Management"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "VPN IPsec ISAKMP"
    protocol    = "udp"
    from_port   = 500
    to_port     = 500
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "VPN NAT-T"
    protocol    = "udp"
    from_port   = 4500
    to_port     = 4500
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ESP Protocol"
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

  tags = { Name = "FortiGate-SG" }
}

# FortiGate Network Interfaces
resource "aws_network_interface" "fgt_public_eni" {
  subnet_id       = data.aws_subnet.public_subnet.id
  description     = "FortiGate Public Interface"
  security_groups = [aws_security_group.fortigate_sg.id]
  tags            = { Name = "FortiGate-Public-ENI" }
}

resource "aws_network_interface" "fgt_private_eni" {
  subnet_id         = data.aws_subnet.private_subnet.id
  description       = "FortiGate Private Interface"
  source_dest_check = true
  security_groups   = [aws_security_group.fortigate_sg.id]
  tags              = { Name = "FortiGate Private Interface" }
}

resource "aws_eip_association" "eip_assoc" {
  allocation_id        = aws_eip.fgt_eip.id
  network_interface_id = aws_network_interface.fgt_public_eni.id
}

# FortiGate EC2 instance
resource "aws_instance" "fgtvm" {
  ami                    = var.fgt_ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  availability_zone      = var.az

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.fgt_public_eni.id
  }

  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.fgt_private_eni.id
  }

  user_data = file("fgtvm.conf") # your FortiGate VPN configurations explicitly

  tags = { Name = "FortiGateVM" }
}

# AWS VPN Resources
resource "aws_vpn_gateway" "it_vgw" {
  vpc_id = data.aws_vpc.existing_vpc.id
  tags   = { Name = "IT-VGW-US" }
}

resource "aws_customer_gateway" "fgt_cgw" {
  bgp_asn    = 65001
  ip_address = aws_eip.fgt_eip.public_ip
  type       = "ipsec.1"
  tags       = { Name = "FortiGate-CGW-US" }
}

resource "aws_vpn_connection" "vpn_conn" {
  customer_gateway_id = aws_customer_gateway.fgt_cgw.id
  vpn_gateway_id      = aws_vpn_gateway.it_vgw.id
  type                = "ipsec.1"
  static_routes_only  = false
  tags                = { Name = "IT-to-RND-VPN" }
}

# Automated Route addition
resource "aws_route" "vpn_route" {
  route_table_id         = data.aws_route_table.existing_private_rt.id
  destination_cidr_block = "10.1.4.0/22"
  network_interface_id   = aws_network_interface.fgt_private_eni.id
}


# Outputs explicitly for Username/Password
output "fortigate_username" {
  value = "admin"
}

output "fortigate_password" {
  value = aws_instance.fgtvm.id
}



