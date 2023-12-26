terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  access_key = "" 
  secret_key = "" 
  region     = "us-east-1"
}

# Creating VPC,name, CIDR and Tags
resource "aws_vpc" "myvpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  tags = {
    Name = "myvpc"
  }
}

# Creating Public Subnets in VPC
resource "aws_subnet" "myvpc-public-1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1a"

  tags = {
    Name = "myvpc-public"
  }
}

# resource "aws_subnet" "dev-public-2" {
#   vpc_id                  = aws_vpc.dev.id
#   cidr_block              = "10.0.2.0/24"
#   map_public_ip_on_launch = "true"
#   availability_zone       = "us-east-1b"

#   tags = {
#     Name = "dev-public-2"
#   }
# }

# Creating Internet Gateway in AWS VPC
resource "aws_internet_gateway" "myvpc-igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "myvpcigw"
  }
}

resource "aws_eip" "eip" {
  vpc = true
}

# Creating Route Tables for Internet gateway
resource "aws_route_table" "myvpc-rt" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myvpc-igw.id
  }

  tags = {
    Name = "myvpc-rt"
  }
}

# Creating Route Associations public subnets
resource "aws_route_table_association" "myvpc-public-1-a" {
  subnet_id      = aws_subnet.myvpc-public-1.id
  route_table_id = aws_route_table.myvpc-rt.id
}

# Creating EC2 instances in public subnets
resource "aws_instance" "server-1" {
  ami                         = "ami-03cf1a25c0360a382"
  instance_type               = "t2.micro"
  key_name                    = "project"
  subnet_id                   = aws_subnet.myvpc-public-1.id
  associate_public_ip_address = "true"
  tags = {
    Name = "Server"
  }
}

resource "aws_default_security_group" "rulesg" {
  vpc_id = aws_vpc.myvpc.id
  # Inbound Rules
  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #RDP access from anywhere
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Rules
  # Internet access to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

