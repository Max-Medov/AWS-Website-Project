########################################
# alb_acm.tf
########################################

resource "aws_lb" "wp_alb" {
  name               = "wp-rnd-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [
    aws_subnet.public_subnet.id,
    aws_subnet.public_subnet_2.id
  ]

  tags = { Name = "WP-ALB" }
}

resource "aws_lb_target_group" "wp_tg" {
  name        = "wp-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"

  health_check {
    path                = "/"
    port                = "80"
    matcher             = "200-399"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "WP-TargetGroup"
  }
}

# Request a free AWS certificate
resource "aws_acm_certificate" "wp_cert" {
  domain_name       = var.wp_domain_name
  validation_method = "DNS"
}

# If your domain is in a different account's Route 53, manually create the CNAME from the AWS Console
resource "aws_acm_certificate_validation" "wp_cert_validation" {
  certificate_arn         = aws_acm_certificate.wp_cert.arn
  # If you do automatic DNS in the same account, you'd reference route53 records here.
  validation_record_fqdns = []
}

resource "aws_lb_listener" "wp_https_listener" {
  load_balancer_arn = aws_lb.wp_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.wp_cert_validation.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wp_tg.arn
  }
}

# Optional: HTTP -> HTTPS redirect listener
resource "aws_lb_listener" "wp_http_listener" {
  load_balancer_arn = aws_lb.wp_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_302"
    }
  }
}

