##############################################################################
# EU/failover_alarm_sns.tf
##############################################################################
# If you're already in the same region as your ALB (e.g., eu-west-1),
# make sure the provider here also says region = "eu-west-1"

# 1) SNS Topic in EU
resource "aws_sns_topic" "failover_topic" {
  name = "eu-failover-topic"
}

# 2) CloudWatch Alarm: checks "HealthyHostCount" for your ALB+TargetGroup
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_alarm" {
  alarm_name          = "alb-0-healthy-hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Triggers when the ALB has 0 healthy hosts for 2 consecutive intervals."

  # Trigger the SNS topic when alarm goes to ALARM
  alarm_actions = [
    aws_sns_topic.failover_topic.arn
  ]

  # Automatic dimension references:
  #   - 'arn_suffix' on aws_lb gives "app/wp-rnd-alb/0452cbbf018d407a"
  #   - 'arn_suffix' on aws_lb_target_group gives "targetgroup/wp-tg/29817ffcc3950121"
  dimensions = {
    LoadBalancer = aws_lb.wp_alb.arn_suffix
    TargetGroup  = aws_lb_target_group.wp_tg.arn_suffix
  }

  # Make sure the ALB + TG are created first
  depends_on = [
    aws_lb.wp_alb,
    aws_lb_target_group.wp_tg
  ]
}

# 3) Output the SNS ARN (if needed by IL stack)
output "sns_topic_arn" {
  description = "The ARN of the EU SNS topic used for failover"
  value       = aws_sns_topic.failover_topic.arn
}

