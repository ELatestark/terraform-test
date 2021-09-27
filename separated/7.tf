resource "aws_route53_zone" "private" {
  name = "example.com"
  vpc {
    vpc_id = aws_vpc.vpc_one.id
  }
  vpc {
    vpc_id = aws_vpc.vpc_two.id
  }
}

resource "aws_route53_record" "private1" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "private1.example.com"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.private_instance_vpc_two.private_ip]
}

resource "aws_route53_record" "private2" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "private2.example.com"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.private_instance_vpc_two_2.private_ip]
}

resource "aws_route53_record" "load-balancer" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "load-balancer.example.com"
  type    = "A"

  alias {
    name                   = aws_lb.load_balancer.dns_name
    zone_id                = aws_lb.load_balancer.zone_id
    evaluate_target_health = true
  }
}
