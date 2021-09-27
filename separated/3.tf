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
}

resource "aws_route_table" "route_table_internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}

resource "aws_route_table_association" "route_table_association_spazaig" {
  subnet_id      = aws_subnet.subnet_publaza.id
  route_table_id = aws_route_table.route_table_internet_gateway.id
}

resource "aws_route_table_association" "route_table_association_spazbig" {
  subnet_id      = aws_subnet.subnet_publazb.id
  route_table_id = aws_route_table.route_table_internet_gateway.id
}

resource "aws_vpc_endpoint" "vpc_endpoint" {
  vpc_id            = aws_vpc.vpc.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.us-east-1.s3"
  route_table_ids   = [aws_route_table.route_table_endpoint.id]
}

resource "aws_route_table" "route_table_endpoint" {
  vpc_id = aws_vpc.vpc.id
  route  = []
}

resource "aws_route_table_association" "route_table_association_spazae" {
  subnet_id      = aws_subnet.subnet_privaza.id
  route_table_id = aws_route_table.route_table_endpoint.id
}

resource "aws_route_table_association" "route_table_association_spazbe" {
  subnet_id      = aws_subnet.subnet_privazb.id
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

resource "aws_subnet" "subnet_publazb" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.12.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "tf-sn-publazb"
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

resource "aws_subnet" "subnet_privazb" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.22.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "tf-sn-privazb"
  }
}

resource "aws_network_acl" "network_acl_public" {
  vpc_id = aws_vpc.vpc.id
  subnet_ids = [
    aws_subnet.subnet_publaza.id,
    aws_subnet.subnet_publazb.id
  ]
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
    Name = "tf-nacl-public"
  }
}

resource "aws_network_acl" "network_acl_private" {
  vpc_id = aws_vpc.vpc.id
  subnet_ids = [
    aws_subnet.subnet_privaza.id,
    aws_subnet.subnet_privazb.id
  ]
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

resource "aws_security_group" "security_group_public" {
  name        = "tf-sg-public"
  description = "tf-sg-public"
  vpc_id      = aws_vpc.vpc.id
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
  vpc_id      = aws_vpc.vpc.id
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

resource "aws_security_group" "security_group_bastion" {
  name        = "tf-sg-bastion"
  description = "tf-sg-bastion"
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

resource "aws_security_group" "security_group_alb" {
  name        = "tf-sg-alb"
  description = "tf-sg-alb"
  vpc_id      = aws_vpc.vpc.id
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
    cidr_blocks = ["10.0.0.0/16"]
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
  vpc_id                        = aws_vpc.vpc.id
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

resource "aws_launch_configuration" "launch_configuration" {
  name_prefix     = "tf-lc-ec2-"
  image_id        = "ami-087c17d1fe0178315"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.security_group_private.id]
  metadata_options {
    http_endpoint = "enabled"
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

output "alb_dns_name" {
  value       = aws_alb.alb.dns_name
  description = "ALB DNS-name"
}
