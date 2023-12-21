# --- ALB ---

resource "aws_security_group" "http" {
  name_prefix = "http-sg-"
  description = "Allow all HTTP/HTTPS traffic from public"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = [80, 443]
    content {
      protocol    = "tcp"
      from_port   = ingress.value
      to_port     = ingress.value
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "main" {
  name               = "${var.name}-${var.env}-alb"
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id
  security_groups    = [aws_security_group.http.id]
}

resource "aws_lb_target_group" "app" {
  name_prefix = "app-"
  vpc_id      = aws_vpc.main.id
  protocol    = "HTTP"
  port        = 80
  target_type = "ip"

  #TODO add an other path in API for helth checks
  health_check {
    enabled             = true
    path                = "/find"
    port                = 80
    matcher             = 200
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

#How we access the lb
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.id
  }
}

resource "aws_lb_listener" "https" {
  depends_on        = [time_sleep.api_cert_dns]
  load_balancer_arn = aws_lb.main.id
  port              = 443
  protocol          = "HTTPS"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.id
  }

  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate.api_cert.arn
}

# --- ACM for custom Domain ---

resource "aws_acm_certificate" "api_cert" {
  # provider          = aws.us_east_1
  domain_name       = "api.${var.domain}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "api_cert_dns" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.api_cert.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.api_cert.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.api_cert.domain_validation_options)[0].resource_record_type
  zone_id         = var.hosted_zone_id
  ttl             = 300
}

resource "time_sleep" "api_cert_dns" {
  depends_on = [aws_route53_record.api_cert_dns]

  create_duration = "60s"
}

# --- Route 53 Custom domain ---

resource "aws_route53_record" "api" {
  zone_id = var.hosted_zone_id
  type    = "CNAME"
  ttl     = "300"
  name    = "api.${var.domain}"
  records = [aws_lb.main.dns_name]
}

output "alb_url" {
  value = aws_lb.main.dns_name
}
