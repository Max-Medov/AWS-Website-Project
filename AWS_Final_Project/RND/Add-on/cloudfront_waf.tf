provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  profile = var.aws_profile
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "default"
}

variable "domain_name" {
  default = "main-wp.medov.click"
}

# 1. Request ACM Certificate in us-east-1 for CloudFront
resource "aws_acm_certificate" "cloudfront_cert" {
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "CloudFrontCert"
  }
}

output "acm_validation_dns_record" {
  value = {
    name  = tolist(aws_acm_certificate.cloudfront_cert.domain_validation_options)[0].resource_record_name
    type  = tolist(aws_acm_certificate.cloudfront_cert.domain_validation_options)[0].resource_record_type
    value = tolist(aws_acm_certificate.cloudfront_cert.domain_validation_options)[0].resource_record_value
  }
  description = "Create this CNAME in Route 53 (in the management account) to validate the ACM cert."
}


# 3. WAF Web ACL (optional security for CloudFront)
resource "aws_wafv2_web_acl" "wordpress_acl" {
  name  = "wordpress-acl"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "wordpressWAF"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 0

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSet"
      sampled_requests_enabled   = true
    }
  }
}

# 4. CloudFront Distribution with Origin Failover + WAF + ACM
resource "aws_cloudfront_distribution" "wordpress_distribution" {
  depends_on = [aws_acm_certificate.cloudfront_cert]

  enabled             = true
  aliases             = [var.domain_name]
  default_root_object = "index.php"

  origin {
    domain_name = "wp.medov.click" # Primary origin (EU ALB)
    origin_id   = "wordpress-eu-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  origin {
    domain_name = "wp-us.medov.click" # Secondary origin (US ALB)
    origin_id   = "wordpress-us-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  origin_group {
    origin_id = "wordpress-origin-failover"

    failover_criteria {
      status_codes = [500, 502, 503, 504]
    }

    member {
      origin_id = "wordpress-eu-origin"
    }

    member {
      origin_id = "wordpress-us-origin"
    }
  }

  default_cache_behavior {
    target_origin_id       = "wordpress-origin-failover"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cloudfront_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  web_acl_id = aws_wafv2_web_acl.wordpress_acl.arn

  tags = {
    Environment = "production"
    App         = "wordpress"
  }
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain to use in Route 53"
  value       = aws_cloudfront_distribution.wordpress_distribution.domain_name
}


