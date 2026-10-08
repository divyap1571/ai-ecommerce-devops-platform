terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.6.0"
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "mern_vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "mern-devops-vpc"
  }
}

resource "aws_internet_gateway" "mern_igw" {
  vpc_id = aws_vpc.mern_vpc.id

  tags = {
    Name = "mern-devops-igw"
  }
}

resource "aws_subnet" "mern_public_subnet" {
  vpc_id                  = aws_vpc.mern_vpc.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "mern-public-subnet"
  }
}

resource "aws_route_table" "mern_public_rt" {
  vpc_id = aws_vpc.mern_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mern_igw.id
  }

  tags = {
    Name = "mern-public-route-table"
  }
}

resource "aws_route_table_association" "mern_public_association" {
  subnet_id      = aws_subnet.mern_public_subnet.id
  route_table_id = aws_route_table.mern_public_rt.id
}

resource "aws_security_group" "mern_sg" {
  name        = "mern-devops-sg"
  description = "Security group for MERN DevOps application"
  vpc_id      = aws_vpc.mern_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Application"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mern-devops-sg"
  }
}



resource "aws_instance" "mern_server" {
  ami                         = "ami-065d2b03fb493085a"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.mern_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.mern_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "mern-devops-server"
  }
}
