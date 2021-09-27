provider "aws" {}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name = "tf-vpc"
  }
}


resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "tf-ig"
  }
}

resource "aws_route_table" "route_table_internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = {
    Name = "tf-rt-ig"
  }
}

resource "aws_route_table_association" "route_table_association_spazaig" {
  subnet_id      = aws_subnet.subnet_publaza.id
  route_table_id = aws_route_table.route_table_internet_gateway.id
}

resource "aws_vpc_endpoint" "vpc_endpoint" {
  vpc_id            = aws_vpc.vpc.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.us-east-1.s3"
  tags = {
    Name = "tf-vpc-ep"
  }
}

resource "aws_route_table" "route_table_endpoint" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "tf-rt-ep"
  }
}

resource "aws_vpc_endpoint_route_table_association" "vpc_endpoint_route_table_association" {
  route_table_id  = aws_route_table.route_table_endpoint.id
  vpc_endpoint_id = aws_vpc_endpoint.vpc_endpoint.id
}

resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.subnet_privaza.id
  route_table_id = aws_route_table.route_table_endpoint.id
}

resource "aws_subnet" "subnet_publaza" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "tf-sn-publaza"
  }
}

resource "aws_subnet" "subnet_privaza" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.21.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "tf-sn-privaza"
  }
}

resource "aws_network_acl" "network_acl_public" {
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = [aws_subnet.subnet_publaza.id]
  ingress {
    rule_no    = 1
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    rule_no    = 1
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

resource "aws_network_acl" "network_acl_private" {
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = [aws_subnet.subnet_privaza.id]
  ingress {
    rule_no    = 1
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    rule_no    = 1
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = {
    Name = "tf-nacl-private"
  }
}

resource "aws_security_group" "security_group_bastion" {
  name        = "tf-security-group-bastion-name"
  description = "tf-security-group-bastion-description"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "description"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "description"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_security_group" "security_group_private" {
  name        = "tf-sg-private"
  description = "tf-sg-private"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "description"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "description"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "instance_bastion" {
  ami                    = "ami-087c17d1fe0178315"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet_publaza.id
  vpc_security_group_ids = [aws_security_group.security_group_bastion.id]
  tags = {
    Name = "tf-ec2-bastion"
  }
  user_data = <<-EOF
              #!/bin/bash
              adduser teacher
              usermod -a -G wheel teacher
              echo 'teacher        ALL=(ALL)       NOPASSWD: ALL' >> /etc/sudoers
              mkdir /home/teacher/.ssh
              chown teacher:teacher /home/teacher/.ssh
              chmod 700 /home/teacher/.ssh
              cd /home/teacher/.ssh
              echo ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCkBIEsfJD6d0J4tqTnVq4z3Ve0bop71b+27j75gncRsLdAHLVg/InhJdrtnVszNGzPIPTXM8jsb/cc0e0JDD7Teoqz0YxJH+ZhY5Y6iy5n8Vx+CCWr5Rra5IpfJclvDPbH+okiUqGyt1fmvS+VkoBWxOFiAOsfdSdTwJWyGs0kplZouOh93cRc/9mp16mNcR5B86+ORLrMZCq3ZGVj2F3YjlhXb1/aUz7Mi1E6Ze9UQQe2oKqf4w8wXIiSejCcrsZ9CT6SX28Kqw2Ilb+7cr84vXIQDKxZySupztn8qMFlDvtoeK4b+RvEtpRmJaC/no9yjTeDTnBYVsV+vQvxiaaeLzkbPRhd0Ovlayoz/gXqI4DOCaQTfISHxG7X+NLfpW6Hmvgf+2i9OStUMJatDx6y1BAj5cjBKo1JRS73U2o5wYYTAlq6jaDAUzWE8Ili7cZ2Qx2dz5uFq6S8NteIt9yR6LsfaHYKG/5WmaA3LOnYAqV+S7nq2WQVQ2Z5bzpJC9s= andrey@MBP-Andrey > authorized_keys
              chown teacher:teacher /home/teacher/.ssh/authorized_keys
              chmod 600 /home/teacher/.ssh/authorized_keys
              EOF
}

resource "aws_instance" "instance_privaza" {
  ami                    = "ami-087c17d1fe0178315"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet_privaza.id
  vpc_security_group_ids = [aws_security_group.security_group_private.id]
  iam_instance_profile   = aws_iam_instance_profile.iam_instance_profile.name
  metadata_options {
    http_endpoint = "enabled"
  }
  tags = {
    Name = "tf-ec2-privaza"
  }
  user_data = <<-EOF
              #!/bin/bash
              adduser teacher
              usermod -a -G wheel teacher
              echo 'teacher        ALL=(ALL)       NOPASSWD: ALL' >> /etc/sudoers
              mkdir /home/teacher/.ssh
              chown teacher:teacher /home/teacher/.ssh
              chmod 700 /home/teacher/.ssh
              cd /home/teacher/.ssh
              echo ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCkBIEsfJD6d0J4tqTnVq4z3Ve0bop71b+27j75gncRsLdAHLVg/InhJdrtnVszNGzPIPTXM8jsb/cc0e0JDD7Teoqz0YxJH+ZhY5Y6iy5n8Vx+CCWr5Rra5IpfJclvDPbH+okiUqGyt1fmvS+VkoBWxOFiAOsfdSdTwJWyGs0kplZouOh93cRc/9mp16mNcR5B86+ORLrMZCq3ZGVj2F3YjlhXb1/aUz7Mi1E6Ze9UQQe2oKqf4w8wXIiSejCcrsZ9CT6SX28Kqw2Ilb+7cr84vXIQDKxZySupztn8qMFlDvtoeK4b+RvEtpRmJaC/no9yjTeDTnBYVsV+vQvxiaaeLzkbPRhd0Ovlayoz/gXqI4DOCaQTfISHxG7X+NLfpW6Hmvgf+2i9OStUMJatDx6y1BAj5cjBKo1JRS73U2o5wYYTAlq6jaDAUzWE8Ili7cZ2Qx2dz5uFq6S8NteIt9yR6LsfaHYKG/5WmaA3LOnYAqV+S7nq2WQVQ2Z5bzpJC9s= andrey@MBP-Andrey > authorized_keys
              chown teacher:teacher /home/teacher/.ssh/authorized_keys
              chmod 600 /home/teacher/.ssh/authorized_keys
              EOF
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket_prefix = "tf-s3-"
  acl           = "private"
  versioning {
    enabled = true
  }
  lifecycle_rule {
    enabled = true
    id      = "tf-s3-lsr"
    prefix  = "/"
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    noncurrent_version_transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    expiration {
      days = 90
    }
    noncurrent_version_expiration {
      days = 90
    }
  }
  tags = {
    Name = "tf-s3"
  }
}

resource "aws_s3_bucket_object" "s3_bucket_object_1" {
  bucket        = aws_s3_bucket.s3_bucket.id
  key           = "key_object"
  acl           = "private"
  storage_class = "STANDARD"
  source        = "file_1.txt"
}

resource "aws_s3_bucket_object" "s3_bucket_object_2" {
  bucket        = aws_s3_bucket.s3_bucket.id
  key           = "key_object"
  acl           = "private"
  storage_class = "STANDARD"
  source        = "file_2.txt"
}


resource "aws_iam_role" "iam_role" {
  name        = "tf-iam-role"
  description = "tf-iam-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Sid    = ""
      },
    ]
  })
}


resource "aws_iam_role_policy" "iam_role_policy" {
  name = "tf-iam-rp"
  role = aws_iam_role.iam_role.id
  policy = jsonencode({
    Version : "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:*"
        Resource = "*"
      },
    ]
  })
}


resource "aws_iam_instance_profile" "iam_instance_profile" {
  name = "tf-iam-ip"
  path = "/"
  role = aws_iam_role.iam_role.name
}

resource "aws_iam_policy" "iam_policy_tags" {
  name        = "tf-iam-policy-tags"
  description = "tf-iam-policy-tags"
  path        = "/"
  policy      = file("policy_tags.json")
}
