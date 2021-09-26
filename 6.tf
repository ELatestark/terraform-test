provider "aws" {
  access_key = "YOUR_ACCESS_KEY"
  secret_key = "YOUR_SECRET_ACCESS_KEY"
  region     = "eu-central-1"
}

resource "aws_vpc" "vpc-1" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "exam_vpc1"
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

resource "aws_internet_gateway" "igw-1" {
  vpc_id = aws_vpc.vpc-1.id

  tags = {
    name = "exam_igw-2"
  }
}

resource "aws_route_table" "RT-public-VPC-1" {
  vpc_id = aws_vpc.vpc-1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-1.id
  }

  tags = {
    Name = "exam_public_route-VPC-1"
  }
}

resource "aws_route_table_association" "route-assoc-public-subnet-VPC-1" {
  subnet_id      = aws_subnet.exam-subnet-public-1.id
  route_table_id = aws_route_table.RT-public-VPC-1.id
}

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

resource "aws_instance" "jumpbox-instance" {
  ami                    = "ami-07df274a488ca9195"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.exam-subnet-public-1.id
  vpc_security_group_ids = [aws_security_group.SG-SSH-ICMP-anywhere-VPC-1.id]
  user_data              = <<-EOF
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
              mkdir /root/.aws
              cd /root/.aws
              echo -e "[default]\noutput = table\nregion = eu-central-1" > config
              chmod 600 /root/.aws/config
              echo -e "[default]\naws_access_key_id = YOUR_ACCESS_KEY\naws_secret_access_key = YOUR_SECRET_ACCESS_KEY" > credentials
              chmod 600 /root/.aws/credentials
              EC2_ID="`curl http://169.254.169.254/latest/meta-data/instance-id`"
              EC2_AWSAVZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
              EC2_REGION=$${EC2_AWSAVZONE::-1}
              VOLUME="`aws ec2 describe-volumes  --filters Name=attachment.device,Values=/dev/xvda Name=attachment.instance-id,Values=$EC2_ID --query 'Volumes[*].{ID:VolumeId}' --region $EC2_REGION --output text`"
              aws ec2 modify-volume --region $EC2_REGION --volume-id $VOLUME --size 9 --volume-type gp2
              sleep 45
              growpart /dev/xvda 1
              xfs_growfs -d /
              echo -e 'EC2_ID="`curl http://169.254.169.254/latest/meta-data/instance-id`"\nEC2_AWSAVZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)\nEC2_REGION=$${EC2_AWSAVZONE::-1}\nVOLUME="`aws ec2 describe-volumes  --filters Name=attachment.device,Values=/dev/xvda Name=attachment.instance-id,Values=$EC2_ID --query 'Volumes[*].{ID:VolumeId}' --region $EC2_REGION --output text`"\naws ec2 modify-volume --region $EC2_REGION --volume-id $VOLUME --size 9 volume-type gp2\nsleep 60\ngrowpart /dev/xvda 1\nxfs_growfs -d /' > /root/readme.txt
              EOF

  tags = {
    "Name" = "Bastion"
  }
}
