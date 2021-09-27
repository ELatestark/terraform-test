provider "aws" {
  access_key = "****"
  secret_key = "****"
  region     = "eu-central-1"
}

////////////////////////////////////////////////////////////////////////////////
//                                    VPCs


resource "aws_vpc" "vpc_1" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name = "tf-vpc1"
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

////////////////////////////////////////////////////////////////////////////////
//                                Peering, GWs, RTs


resource "aws_vpc_peering_connection" "vpc_peering_connection" {
  peer_vpc_id = aws_vpc.vpc_1.id
  vpc_id      = aws_vpc.vpc_2.id
  auto_accept = true
  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }
  tags = {
    Name = "tf-vpc-pc"
  }
}

resource "aws_internet_gateway" "igw_vpc1" {
  vpc_id = aws_vpc.vpc_1.id
  tags = {
    name = "tf-igw-vpc1"
  }
}

resource "aws_route_table" "rt_vpc1" {
  vpc_id = aws_vpc.vpc_1.id
  route {
    cidr_block                = "10.2.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering_connection.id
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_vpc1.id
  }
  tags = {
    Name = "tf-rt-vpc1"
  }
}

resource "aws_route_table_association" "rt_assoc_vpc1_public" {
  subnet_id      = aws_subnet.subnet_vpc1_public.id
  route_table_id = aws_route_table.rt_vpc1.id
}

resource "aws_route_table_association" "rt_assoc_vpc1_private" {
  subnet_id      = aws_subnet.subnet_vpc1_private.id
  route_table_id = aws_route_table.rt_vpc1.id
}

resource "aws_internet_gateway" "igw_vpc2" {
  vpc_id = aws_vpc.vpc_2.id
  tags = {
    Name = "tf-igw-vpc2"
  }
}

resource "aws_route_table" "rt_vpc2" {
  vpc_id = aws_vpc.vpc_2.id
  route {
    cidr_block                = "10.1.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering_connection.id
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_vpc2.id
  }
  tags = {
    Name = "tf-rt-vpc2"
  }
}

resource "aws_route_table_association" "rt_assoc_vpc2_public_a" {
  subnet_id      = aws_subnet.subnet_vpc2_public_a.id
  route_table_id = aws_route_table.rt_vpc2.id
}

resource "aws_route_table_association" "rt_assoc_vpc2_public_b" {
  subnet_id      = aws_subnet.subnet_vpc2_public_b.id
  route_table_id = aws_route_table.rt_vpc2.id
}

resource "aws_route_table_association" "rt_assoc_vpc2_private_a" {
  subnet_id      = aws_subnet.subnet_vpc2_private_a.id
  route_table_id = aws_route_table.rt_vpc2.id
}

resource "aws_route_table_association" "rt_assoc_vpc2_private_b" {
  subnet_id      = aws_subnet.subnet_vpc2_private_b.id
  route_table_id = aws_route_table.rt_vpc2.id
}

resource "aws_vpc_endpoint" "vpc_endpoint" {
  vpc_id            = aws_vpc.vpc_2.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.eu-central-1.s3"
  tags = {
    Name = "tf-vpc-ep-vpc2"
  }
}

resource "aws_vpc_endpoint_route_table_association" "vpc_endpoint_rt_assoc" {
  route_table_id  = aws_route_table.rt_vpc2.id
  vpc_endpoint_id = aws_vpc_endpoint.vpc_endpoint.id
}

////////////////////////////////////////////////////////////////////////////////
//                                  Subnets


resource "aws_subnet" "subnet_vpc1_public" {
  vpc_id                  = aws_vpc.vpc_1.id
  cidr_block              = "10.1.11.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "tf-vpc1-sn-publ"
  }
}

resource "aws_subnet" "subnet_vpc1_private" {
  vpc_id                  = aws_vpc.vpc_1.id
  cidr_block              = "10.1.21.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "tf-vpc1-sn-priv"
  }
}

resource "aws_subnet" "subnet_vpc2_public_a" {
  vpc_id                  = aws_vpc.vpc_2.id
  cidr_block              = "10.2.11.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "tf-vpc2-sn-publ-a"
  }
}

resource "aws_subnet" "subnet_vpc2_public_b" {
  vpc_id                  = aws_vpc.vpc_2.id
  cidr_block              = "10.2.12.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "tf-vpc2-sn-publ-b"
  }
}

resource "aws_subnet" "subnet_vpc2_private_a" {
  vpc_id                  = aws_vpc.vpc_2.id
  cidr_block              = "10.2.21.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "tf-vpc2-sn-priv-a"
  }
}

resource "aws_subnet" "subnet_vpc2_private_b" {
  vpc_id                  = aws_vpc.vpc_2.id
  cidr_block              = "10.2.22.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "tf-vpc2-sn-priv-b"
  }
}

////////////////////////////////////////////////////////////////////////////////
//                                   NACLs


resource "aws_network_acl" "nacl_vpc1_public" {
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
    Name = "tf-vpc1-nacl-publ"
  }
}

resource "aws_network_acl" "nacl_vpc1_private" {
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
    Name = "tf-vpc1-nacl-priv"
  }
}

resource "aws_network_acl" "nacl_public" {
  vpc_id = aws_vpc.vpc_2.id
  subnet_ids = [
    aws_subnet.subnet_vpc2_public_a.id,
    aws_subnet.subnet_vpc2_public_b.id
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
    Name = "tf-vpc2-nacl-publ"
  }
}

resource "aws_network_acl" "nacl_private" {
  vpc_id = aws_vpc.vpc_2.id
  subnet_ids = [
    aws_subnet.subnet_vpc2_private_a.id,
    aws_subnet.subnet_vpc2_private_b.id
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
    Name = "tf-vpc2-nacl-priv"
  }
}

////////////////////////////////////////////////////////////////////////////////
//                               Security Groups


resource "aws_security_group" "SG_bastion" {
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
  egress {
    description = "meta-data"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "SG_public" {
  name        = "tf-sg-vpc2-public"
  description = "tf-sg-vpc2-public"
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
    security_groups = [aws_security_group.SG_bastion.id]
  }
  egress {
    description = "description"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "SG_private" {
  name        = "tf-sg-vpc2-private"
  description = "tf-sg-vpc2-private"
  vpc_id      = aws_vpc.vpc_2.id
  ingress {
    description     = "description"
    protocol        = "tcp"
    from_port       = 8888
    to_port         = 8888
    security_groups = [aws_security_group.SG_alb.id]
  }
  ingress {
    description     = "description"
    protocol        = "tcp"
    from_port       = 22
    to_port         = 22
    security_groups = [aws_security_group.SG_bastion.id]
  }
  egress {
    description = "description"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "SG_alb" {
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

////////////////////////////////////////////////////////////////////////////////
//                                EC2s


resource "aws_instance" "instance_bastion" {
  ami                    = "ami-07df274a488ca9195"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet_vpc1_public.id
  vpc_security_group_ids = [aws_security_group.SG_bastion.id]
  user_data              = file("user_files/bastion.sh")
  tags = {
    Name = "tf-ec2-bastion"
  }
}

resource "aws_instance" "instance_nginx_a" {
  ami                    = "ami-07df274a488ca9195"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet_vpc2_private_a.id
  vpc_security_group_ids = [aws_security_group.SG_private.id]
  user_data              = file("user_files/nginx.sh")
  depends_on             = [aws_vpc_endpoint.vpc_endpoint]
  metadata_options {
    http_endpoint = "enabled"
  }
  tags = {
    Name = "tf-ec2-nginx-a"
  }
}

resource "aws_instance" "instance_nginx_b" {
  ami                    = "ami-07df274a488ca9195"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet_vpc2_private_b.id
  vpc_security_group_ids = [aws_security_group.SG_private.id]
  user_data              = file("user_files/nginx.sh")
  depends_on             = [aws_vpc_endpoint.vpc_endpoint]
  metadata_options {
    http_endpoint = "enabled"
  }
  tags = {
    Name = "tf-ec2-nginx-b"
  }
}

////////////////////////////////////////////////////////////////////////////////
//                                Load Balancer


resource "aws_alb" "alb" {
  name                       = "tf-alb"
  internal                   = false
  load_balancer_type         = "application"
  enable_deletion_protection = false
  security_groups            = [aws_security_group.SG_alb.id]
  subnets = [
    aws_subnet.subnet_vpc2_public_a.id,
    aws_subnet.subnet_vpc2_public_b.id
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

resource "aws_alb_target_group_attachment" "alb_target_group_attachment_a" {
  target_group_arn = aws_alb_target_group.alb_target_group.arn
  target_id        = aws_instance.instance_nginx_a.id
  port             = 8888
}

resource "aws_alb_target_group_attachment" "alb_target_group_attachment_b" {
  target_group_arn = aws_alb_target_group.alb_target_group.arn
  target_id        = aws_instance.instance_nginx_b.id
  port             = 8888
}

////////////////////////////////////////////////////////////////////////////////
//                            Auto Scaling Group


resource "aws_launch_configuration" "launch_configuration" {
  name            = "tf-lc"
  image_id        = "ami-07df274a488ca9195"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.SG_private.id]
  user_data       = file("user_files/nginx.sh")
  metadata_options {
    http_endpoint = "enabled"
  }
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
    aws_subnet.subnet_vpc2_private_a.id,
    aws_subnet.subnet_vpc2_private_b.id,
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

////////////////////////////////////////////////////////////////////////////////
//                                 S3


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
  key           = "object_key"
  acl           = "private"
  storage_class = "STANDARD"
  source        = "user_files/file1.txt"
}

resource "aws_s3_bucket_object" "s3_bucket_object_2" {
  bucket        = aws_s3_bucket.s3_bucket.id
  key           = "object_key"
  acl           = "private"
  storage_class = "STANDARD"
  source        = "user_files/file2.txt"
}

////////////////////////////////////////////////////////////////////////////////
//                               IAM


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
      }
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
        Effect = "Allow"
        Action = [
          "s3:Get*",
          "s3:List*"
        ]
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
  policy      = file("user_files/policies.json")
}

////////////////////////////////////////////////////////////////////////////////
//                                 Route 53

resource "aws_route53_zone" "route53_zone" {
  name = "example.net"
  vpc {
    vpc_id = aws_vpc.vpc_1.id
  }
  vpc {
    vpc_id = aws_vpc.vpc_2.id
  }
}

resource "aws_route53_record" "route53_record_1" {
  zone_id = aws_route53_zone.route53_zone.zone_id
  name    = "aza.example.net"
  type    = "A"
  ttl     = "600"
  records = [aws_instance.instance_nginx_a.private_ip]
}

resource "aws_route53_record" "route53_record_2" {
  zone_id = aws_route53_zone.route53_zone.zone_id
  name    = "azb.example.net"
  type    = "A"
  ttl     = "600"
  records = [aws_instance.instance_nginx_b.private_ip]
}

resource "aws_route53_record" "load-balancer" {
  zone_id = aws_route53_zone.route53_zone.zone_id
  name    = "alb.example.net"
  type    = "A"
  alias {
    name                   = aws_alb.alb.dns_name
    zone_id                = aws_alb.alb.zone_id
    evaluate_target_health = true
  }
}
