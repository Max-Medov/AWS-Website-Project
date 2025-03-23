provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

########################################
# VPC
########################################
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags                 = { Name = "Lovely-RD-VPC-EU" }
}

########################################
# FIRST PUBLIC SUBNET (Original)
########################################
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.az
  tags                    = { Name = "Public-Subnet-EU" }
}

########################################
# FIRST PRIVATE SUBNET (Original)
########################################
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.az
  tags              = { Name = "Private-Subnet-EU" }
}

########################################
# Internet Gateway
########################################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = "IGW-EU" }
}

########################################
# NAT EIP
########################################
resource "aws_eip" "nat_eip" {
  depends_on = [aws_internet_gateway.igw]
  domain = "vpc"
  tags       = { Name = "NAT-EIP-EU" }
}

########################################
# NAT Gateway (in the first public subnet)
########################################
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  tags          = { Name = "NAT-GW-EU" }
}

########################################
# Public Route Table & Association (Original Subnet)
########################################
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "Public-RT-EU" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

########################################
# Private Route Table & Association (Original Subnet)
########################################
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "Private-RT-EU" }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

########################################
# NEW: SECOND PUBLIC SUBNET (AZ2)
########################################
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidr_2
  map_public_ip_on_launch = true
  availability_zone       = var.az2
  tags                    = { Name = "Public-Subnet-EU-2" }
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

########################################
# NEW: SECOND PRIVATE SUBNET (AZ2)
########################################
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidr_2
  availability_zone = var.az2
  tags              = { Name = "Private-Subnet-EU-2" }
}

resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

