provider "aws" {
  access_key = "****"
  secret_key = "****"
  region     = "eu-central-1"
}

//VPC
resource "aws_vpc" "vpc-1" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "exam_vpc1"
  }
}

resource "aws_vpc" "vpc-2" {
  cidr_block           = "10.1.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "exam_vpc2"
  }
}

resource "aws_vpc_peering_connection" "peering-between-vpc" {
  vpc_id      = aws_vpc.vpc-1.id
  peer_vpc_id = aws_vpc.vpc-2.id
  auto_accept = true
}

resource "aws_vpc_peering_connection_options" "peering-options" {
  vpc_peering_connection_id = aws_vpc_peering_connection.peering-between-vpc.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_vpc_to_remote_classic_link = true
    allow_classic_link_to_remote_vpc = true
  }
}

resource "aws_subnet" "exam-subnet-public-1" {
  vpc_id                  = aws_vpc.vpc-1.id
  cidr_block              = "10.0.10.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "eu-central-1a"

  tags = {
    Name = "exam_public_subnet-1"
  }
}

resource "aws_subnet" "exam-subnet-public-2" {
  vpc_id                  = aws_vpc.vpc-2.id
  cidr_block              = "10.1.10.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "eu-central-1a"

  tags = {
    Name = "exam_public_subnet-2"
  }
}

resource "aws_subnet" "exam-subnet-private-1" {
  vpc_id            = aws_vpc.vpc-1.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "exam_private_subnet-1"
  }
}

resource "aws_subnet" "exam-subnet-private-2" {
  vpc_id            = aws_vpc.vpc-2.id
  cidr_block        = "10.1.20.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "exam_private_subnet-2"
  }
}

resource "aws_internet_gateway" "igw-1" {
  vpc_id = aws_vpc.vpc-1.id

  tags = {
    name = "exam_igw-2"
  }
}

resource "aws_internet_gateway" "igw-2" {
  vpc_id = aws_vpc.vpc-2.id

  tags = {
    name = "exam_igw-2"
  }
}

//route table for public subnet
resource "aws_route_table" "RT-public-VPC-1" {
  vpc_id = aws_vpc.vpc-1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-1.id
  }

  route {
    cidr_block                = "10.1.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.peering-between-vpc.id
  }

  tags = {
    Name = "exam_public_route-VPC-1"
  }
}

//route table for public subnet
resource "aws_route_table" "RT-public-VPC-2" {
  vpc_id = aws_vpc.vpc-2.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-2.id
  }

  route {
    cidr_block                = "10.0.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.peering-between-vpc.id
  }

  tags = {
    Name = "exam_public_route-VPC-2"
  }
}

resource "aws_route_table" "RT-private-VPC-1" {
  vpc_id = aws_vpc.vpc-1.id

  route {
    cidr_block                = "10.1.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.peering-between-vpc.id
  }

  tags = {
    Name = "exam_private_route-VPC-1"
  }
}

resource "aws_route_table" "RT-private-VPC-2" {
  vpc_id = aws_vpc.vpc-2.id

  route {
    cidr_block                = "10.0.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.peering-between-vpc.id
  }

  tags = {
    Name = "exam_private_route-VPC-2"
  }
}


//route association
resource "aws_route_table_association" "route-assoc-public-subnet-VPC-1" {
  subnet_id      = aws_subnet.exam-subnet-public-1.id
  route_table_id = aws_route_table.RT-public-VPC-1.id
}

//route association
resource "aws_route_table_association" "route-assoc-public-subnet-VPC-2" {
  subnet_id      = aws_subnet.exam-subnet-public-2.id
  route_table_id = aws_route_table.RT-public-VPC-2.id
}

//route association
resource "aws_route_table_association" "route-assoc-private-subnet-VPC-1" {
  subnet_id      = aws_subnet.exam-subnet-private-1.id
  route_table_id = aws_route_table.RT-private-VPC-1.id
}

//route association
resource "aws_route_table_association" "route-assoc-private-subnet-VPC-2" {
  subnet_id      = aws_subnet.exam-subnet-private-2.id
  route_table_id = aws_route_table.RT-private-VPC-2.id
}

//SG for SSH and ICMP
resource "aws_security_group" "SG-SSH-ICMP-anywhere-VPC-1" {
  name   = "SSH-ICMP"
  vpc_id = aws_vpc.vpc-1.id

  ingress {
    description = "SSH anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP anywhere"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SSH-ICMP-anywhere"
  }
}

//SG for SSH and ICMP
resource "aws_security_group" "SG-SSH-ICMP-anywhere-VPC-2" {
  name   = "SSH-ICMP"
  vpc_id = aws_vpc.vpc-2.id

  ingress {
    description = "SSH anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP anywhere"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SSH-ICMP-anywhere"
  }
}

//jumpbox instance
resource "aws_instance" "jumpbox-instance" {
  ami                    = "ami-07df274a488ca9195"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.exam-subnet-public-1.id
  vpc_security_group_ids = [aws_security_group.SG-SSH-ICMP-anywhere-VPC-1.id]
  user_data              = <<-EOF
              #!/bin/bash
              adduser teacher
              usermod -a -G wheel teacher
              echo teacher ALL=(ALL) NOPASSWD: ALL >> /etc/sudoers
              mkdir /home/teacher/.ssh
              chown teacher:teacher /home/teacher/.ssh
              chmod 700 /home/teacher/.ssh
              cd /home/teacher/.ssh
              echo ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCkBIEsfJD6d0J4tqTnVq4z3Ve0bop71b+27j75gncRsLdAHLVg/InhJdrtnVszNGzPIPTXM8jsb/cc0e0JDD7Teoqz0YxJH+ZhY5Y6iy5n8Vx+CCWr5Rra5IpfJclvDPbH+okiUqGyt1fmvS+VkoBWxOFiAOsfdSdTwJWyGs0kplZouOh93cRc/9mp16mNcR5B86+ORLrMZCq3ZGVj2F3YjlhXb1/aUz7Mi1E6Ze9UQQe2oKqf4w8wXIiSejCcrsZ9CT6SX28Kqw2Ilb+7cr84vXIQDKxZySupztn8qMFlDvtoeK4b+RvEtpRmJaC/no9yjTeDTnBYVsV+vQvxiaaeLzkbPRhd0Ovlayoz/gXqI4DOCaQTfISHxG7X+NLfpW6Hmvgf+2i9OStUMJatDx6y1BAj5cjBKo1JRS73U2o5wYYTAlq6jaDAUzWE8Ili7cZ2Qx2dz5uFq6S8NteIt9yR6LsfaHYKG/5WmaA3LOnYAqV+S7nq2WQVQ2Z5bzpJC9s= andrey@MBP-Andrey > authorized_keys
              chown teacher:teacher /home/teacher/.ssh/authorized_keys
              chmod 600 /home/teacher/.ssh/authorized_keys
              EOF

  tags = {
    "Name" = "Bastion"
  }
}
