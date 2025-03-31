resource "aws_wafv2_web_acl" "alb_waf_acl" {
  name        = "alb-wp-waf"
  description = "WAF for ALBs protecting WordPress"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "albWpWafMetric"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

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
      metric_name                = "AWSCommonRules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesWordPressRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesWordPressRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSWordPressRules"
      sampled_requests_enabled   = true
    }
  }
}

# Associate WAF with your ALB
resource "aws_wafv2_web_acl_association" "alb_waf_association" {
  resource_arn = aws_lb.wp_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.alb_waf_acl.arn
}

