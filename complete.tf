provider "aws" {
  region = "eu-central-1"
}

resource "aws_vpc" "vpc_1" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name = "tf-vpc1"
  }
}

resource "aws_vpc_peering_connection" "vpc_peering_connection" {
  vpc_id      = aws_vpc.vpc_1.id
  peer_vpc_id = aws_vpc.vpc_2.id
  auto_accept = true
}

resource "aws_vpc_peering_connection_options" "vpc_peering_connection_options" {
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering_connection.id
  accepter {
    allow_remote_vpc_dns_resolution = true
  }
  requester {
    allow_vpc_to_remote_classic_link = true
    allow_classic_link_to_remote_vpc = true
  }
}

resource "aws_internet_gateway" "internet_gateway_vpc1" {
  vpc_id = aws_vpc.vpc_1.id
  tags = {
    name = "tf-ig-vpc1"
  }
}

resource "aws_route_table" "route_table_vpc1" {
  vpc_id = aws_vpc.vpc_1.id
  route {
    cidr_block                = "10.2.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering_connection.id
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway_vpc1.id
  }
  tags = {
    Name = "tf-rt-vpc1"
  }
}

resource "aws_route_table_association" "route_table_association_vpc1_one" {
  subnet_id      = aws_subnet.subnet_vpc1_public.id
  route_table_id = aws_route_table.route_table_vpc1.id
}

resource "aws_route_table_association" "route_table_association_vpc1_two" {
  subnet_id      = aws_subnet.subnet_vpc1_private.id
  route_table_id = aws_route_table.route_table_vpc1.id
}

resource "aws_network_acl" "network_acl_vpc1_public" {
  vpc_id = aws_vpc.vpc_1.id
  subnet_ids = [
    aws_subnet.subnet_vpc1_public.id
  ]
  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = {
    Name = "tf-nacl-vpc1-public"
  }
}

resource "aws_network_acl" "network_acl_vpc1_private" {
  vpc_id = aws_vpc.vpc_1.id
  subnet_ids = [
    aws_subnet.subnet_vpc1_private.id
  ]
  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = {
    Name = "tf-nacl-vpc1-private"
  }
}

resource "aws_subnet" "subnet_vpc1_public" {
  vpc_id                  = aws_vpc.vpc_1.id
  cidr_block              = "10.1.11.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "tf-sn-vpc1-pu"
  }
}

resource "aws_subnet" "subnet_vpc1_private" {
  vpc_id                  = aws_vpc.vpc_1.id
  cidr_block              = "10.1.21.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "tf-sn-vpc1-pr"
  }
}

resource "aws_security_group" "security_group_bastion" {
  name        = "tf-sg-bastion"
  description = "tf-sg-bastion"
  vpc_id      = aws_vpc.vpc_1.id
  ingress {
    description = "SSH from teacher"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "SSH to VPC1"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["10.1.0.0/16"]
  }
  egress {
    description = "SSH to VPC2"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["10.2.0.0/16"]
  }
}

resource "aws_instance" "instance_bastion" {
  ami                    = "ami-087c17d1fe0178315"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet_vpc1_public.id
  vpc_security_group_ids = [aws_security_group.security_group_bastion.id]
  user_data              = file("user_data/init_bastion.sh")
  tags = {
    "Name" = "tf-ec2-bastion"
  }
}

resource "aws_vpc" "vpc_2" {
  cidr_block           = "10.2.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name = "tf-vpc2"
  }
}

resource "aws_internet_gateway" "internet_gateway_vpc2" {
  vpc_id = aws_vpc.vpc_2.id
  tags = {
    Name = "tf-ig-vpc2"
  }
}

resource "aws_route_table" "route_table_vpc2" {
  vpc_id = aws_vpc.vpc_2.id
  route {
    cidr_block                = "10.1.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering_connection.id
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway_vpc2.id
  }
  tags = {
    Name = "tf-rt-vpc2"
  }
}

resource "aws_route_table_association" "route_table_association_spuazaig" {
  subnet_id      = aws_subnet.subnet_publaza.id
  route_table_id = aws_route_table.route_table_vpc2.id
}

resource "aws_route_table_association" "route_table_association_spuazbig" {
  subnet_id      = aws_subnet.subnet_publazb.id
  route_table_id = aws_route_table.route_table_vpc2.id
}

resource "aws_route_table_association" "route_table_association_sprazaig" {
  subnet_id      = aws_subnet.subnet_privaza.id
  route_table_id = aws_route_table.route_table_vpc2.id
}

resource "aws_route_table_association" "route_table_association_sprazbig" {
  subnet_id      = aws_subnet.subnet_privazb.id
  route_table_id = aws_route_table.route_table_vpc2.id
}


resource "aws_vpc_endpoint" "vpc_endpoint" {
  vpc_id            = aws_vpc.vpc_2.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.us-east-1.s3"
  tags = {
    Name = "tf-vpc-ep"
  }
}

resource "aws_vpc_endpoint_route_table_association" "vpc_endpoint_route_table_association" {
  route_table_id  = aws_route_table.route_table_vpc2.id
  vpc_endpoint_id = aws_vpc_endpoint.vpc_endpoint.id
}


resource "aws_subnet" "subnet_publaza" {
  vpc_id                  = aws_vpc.vpc_2.id
  cidr_block              = "10.2.11.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "tf-sn-publaza"
  }
}

resource "aws_subnet" "subnet_publazb" {
  vpc_id                  = aws_vpc.vpc_2.id
  cidr_block              = "10.2.12.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "tf-sn-publazb"
  }
}

resource "aws_subnet" "subnet_privaza" {
  vpc_id                  = aws_vpc.vpc_2.id
  cidr_block              = "10.2.21.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "tf-sn-privaza"
  }
}

resource "aws_subnet" "subnet_privazb" {
  vpc_id                  = aws_vpc.vpc_2.id
  cidr_block              = "10.2.22.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "tf-sn-privazb"
  }
}

resource "aws_network_acl" "network_acl_public" {
  vpc_id = aws_vpc.vpc_2.id
  subnet_ids = [
    aws_subnet.subnet_publaza.id,
    aws_subnet.subnet_publazb.id
  ]
  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = {
    Name = "tf-nacl-public"
  }
}

resource "aws_network_acl" "network_acl_private" {
  vpc_id = aws_vpc.vpc_2.id
  subnet_ids = [
    aws_subnet.subnet_privaza.id,
    aws_subnet.subnet_privazb.id
  ]
  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    rule_no    = 100
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

resource "aws_security_group" "security_group_public" {
  name        = "tf-sg-public"
  description = "security group for public subnets"
  vpc_id      = aws_vpc.vpc_2.id
  ingress {
    description = "description"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description     = "description"
    protocol        = "tcp"
    from_port       = 22
    to_port         = 22
    security_groups = [aws_security_group.security_group_bastion.id]
  }
  egress {
    description = "description"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "security_group_private" {
  name        = "tf-sg-private"
  description = "tf-sg-private"
  vpc_id      = aws_vpc.vpc_2.id
  ingress {
    description     = "description"
    protocol        = "tcp"
    from_port       = 8888
    to_port         = 8888
    security_groups = [aws_security_group.security_group_alb.id]
  }
  ingress {
    description     = "description"
    protocol        = "tcp"
    from_port       = 22
    to_port         = 22
    security_groups = [aws_security_group.security_group_bastion.id]
  }
  egress {
    description = "description"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "security_group_alb" {
  name        = "tf-sg-alb"
  description = "tf-sg-alb"
  vpc_id      = aws_vpc.vpc_2.id
  ingress {
    description = "description"
    protocol    = "tcp"
    from_port   = 8888
    to_port     = 8888
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "description"
    protocol    = "tcp"
    from_port   = 8888
    to_port     = 8888
    cidr_blocks = ["10.2.0.0/16"]
  }
}

resource "aws_alb" "alb" {
  name                       = "tf-alb"
  internal                   = false
  load_balancer_type         = "application"
  enable_deletion_protection = false
  security_groups            = [aws_security_group.security_group_alb.id]
  subnets = [
    aws_subnet.subnet_publaza.id,
    aws_subnet.subnet_publazb.id
  ]
}

resource "aws_alb_target_group" "alb_target_group" {
  name                          = "tf-alb-tg"
  load_balancing_algorithm_type = "round_robin"
  protocol                      = "HTTP"
  port                          = 8888
  vpc_id                        = aws_vpc.vpc_2.id
  target_type                   = "instance"
  health_check {
    enabled             = true
    protocol            = "HTTP"
    port                = 8888
    path                = "/"
    matcher             = "200"
    interval            = 60
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = aws_alb.alb.arn
  protocol          = "HTTP"
  port              = 8888
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.alb_target_group.arn
  }
}

resource "aws_alb_target_group_attachment" "alb_target_group_attachment_privaza" {
  target_group_arn = aws_alb_target_group.alb_target_group.arn
  target_id        = aws_instance.instance_privaza.id
  port             = 8888
}

resource "aws_alb_target_group_attachment" "alb_target_group_attachment_privazb" {
  target_group_arn = aws_alb_target_group.alb_target_group.arn
  target_id        = aws_instance.instance_privazb.id
  port             = 8888
}


resource "aws_launch_configuration" "launch_configuration" {
  name_prefix     = "tf-lc-ec2-"
  image_id        = "ami-087c17d1fe0178315"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.security_group_private.id]
  metadata_options {
    http_endpoint = "enabled"
  }
  user_data = file("user_data/init_nginx.sh")
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "autoscaling_policy" {
  name        = "tf-asp"
  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = "80"
  }
  autoscaling_group_name = aws_autoscaling_group.autoscaling_group.name
}

resource "aws_autoscaling_group" "autoscaling_group" {
  name                 = "tf-asg"
  launch_configuration = aws_launch_configuration.launch_configuration.name
  vpc_zone_identifier = [
    aws_subnet.subnet_privaza.id,
    aws_subnet.subnet_privazb.id,
  ]
  desired_capacity          = 0
  min_size                  = 1
  max_size                  = 4
  target_group_arns         = [aws_alb_target_group.alb_target_group.arn]
  wait_for_capacity_timeout = "5m"
  health_check_grace_period = 300
  health_check_type         = "EC2"
  force_delete              = false
  depends_on                = [aws_vpc_endpoint.vpc_endpoint]
}

resource "aws_instance" "instance_privaza" {
  ami                    = "ami-087c17d1fe0178315"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet_privaza.id
  vpc_security_group_ids = [aws_security_group.security_group_private.id]
  metadata_options {
    http_endpoint = "enabled"
  }
  user_data = <<-EOF
              #!/bin/bash
              adduser teacher
              usermod -a -G wheel teacher
              mkdir /home/teacher/.ssh
              chown teacher:teacher /home/teacher/.ssh
              chmod 700 /home/teacher/.ssh
              cd /home/teacher/.ssh
              echo ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCkBIEsfJD6d0J4tqTnVq4z3Ve0bop71b+27j75gncRsLdAHLVg/InhJdrtnVszNGzPIPTXM8jsb/cc0e0JDD7Teoqz0YxJH+ZhY5Y6iy5n8Vx+CCWr5Rra5IpfJclvDPbH+okiUqGyt1fmvS+VkoBWxOFiAOsfdSdTwJWyGs0kplZouOh93cRc/9mp16mNcR5B86+ORLrMZCq3ZGVj2F3YjlhXb1/aUz7Mi1E6Ze9UQQe2oKqf4w8wXIiSejCcrsZ9CT6SX28Kqw2Ilb+7cr84vXIQDKxZySupztn8qMFlDvtoeK4b+RvEtpRmJaC/no9yjTeDTnBYVsV+vQvxiaaeLzkbPRhd0Ovlayoz/gXqI4DOCaQTfISHxG7X+NLfpW6Hmvgf+2i9OStUMJatDx6y1BAj5cjBKo1JRS73U2o5wYYTAlq6jaDAUzWE8Ili7cZ2Qx2dz5uFq6S8NteIt9yR6LsfaHYKG/5WmaA3LOnYAqV+S7nq2WQVQ2Z5bzpJC9s= andrey@MBP-Andrey > authorized_keys
              chown teacher:teacher /home/teacher/.ssh/authorized_keys
              chmod 600 /home/teacher/.ssh/authorized_keys
              yum update -y
              amazon-linux-extras install nginx1
              sed -i 's/listen       80;/listen       8888;/' /etc/nginx/nginx.conf
              ip=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
              region=`curl http://169.254.169.254/latest/meta-data/placement/region`
              az=`curl http://169.254.169.254/latest/meta-data/placement/availability-zone`
              echo "Private IP: $ip<br>Region: $region<br>Availability Zone: $az" > /usr/share/nginx/html/index.html
              systemctl start nginx
              systemctl enable nginx
              EOF
  tags = {
    Name = "tf-ec2-init1"
  }
}

resource "aws_instance" "instance_privazb" {
  ami                    = "ami-087c17d1fe0178315"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet_privazb.id
  vpc_security_group_ids = [aws_security_group.security_group_private.id]
  metadata_options {
    http_endpoint = "enabled"
  }
  user_data = <<-EOF
              #!/bin/bash
              adduser teacher
              usermod -a -G wheel teacher
              mkdir /home/teacher/.ssh
              chown teacher:teacher /home/teacher/.ssh
              chmod 700 /home/teacher/.ssh
              cd /home/teacher/.ssh
              echo ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCkBIEsfJD6d0J4tqTnVq4z3Ve0bop71b+27j75gncRsLdAHLVg/InhJdrtnVszNGzPIPTXM8jsb/cc0e0JDD7Teoqz0YxJH+ZhY5Y6iy5n8Vx+CCWr5Rra5IpfJclvDPbH+okiUqGyt1fmvS+VkoBWxOFiAOsfdSdTwJWyGs0kplZouOh93cRc/9mp16mNcR5B86+ORLrMZCq3ZGVj2F3YjlhXb1/aUz7Mi1E6Ze9UQQe2oKqf4w8wXIiSejCcrsZ9CT6SX28Kqw2Ilb+7cr84vXIQDKxZySupztn8qMFlDvtoeK4b+RvEtpRmJaC/no9yjTeDTnBYVsV+vQvxiaaeLzkbPRhd0Ovlayoz/gXqI4DOCaQTfISHxG7X+NLfpW6Hmvgf+2i9OStUMJatDx6y1BAj5cjBKo1JRS73U2o5wYYTAlq6jaDAUzWE8Ili7cZ2Qx2dz5uFq6S8NteIt9yR6LsfaHYKG/5WmaA3LOnYAqV+S7nq2WQVQ2Z5bzpJC9s= andrey@MBP-Andrey > authorized_keys
              chown teacher:teacher /home/teacher/.ssh/authorized_keys
              chmod 600 /home/teacher/.ssh/authorized_keys
              yum update -y
              amazon-linux-extras install nginx1
              sed -i 's/listen       80;/listen       8888;/' /etc/nginx/nginx.conf
              ip=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
              region=`curl http://169.254.169.254/latest/meta-data/placement/region`
              az=`curl http://169.254.169.254/latest/meta-data/placement/availability-zone`
              echo "Private IP: $ip<br>Region: $region<br>Availability Zone: $az" > /usr/share/nginx/html/index.html
              systemctl start nginx
              systemctl enable nginx
              EOF
  tags = {
    Name = "tf-ec2-init2"
  }
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
