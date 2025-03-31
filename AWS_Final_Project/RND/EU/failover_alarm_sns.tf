##############################################################################
# EU/failover_alarm_sns.tf
##############################################################################
# Assumes you already have an AWS provider here with region = "eu-west-1"
# and that your ALB + Target Group are defined in the same folder,
# for example in alb_acm.tf.

#############################################################
# Input variable: We will eventually pass in the US Lambda ARN
#############################################################
variable "us_lambda_arn" {
  type        = string
  description = "The ARN of the US Lambda to subscribe for failover"
  default     = "" # If you don't have it yet, you can leave it blank initially
}

#############################################################
# SNS Topic in EU
#############################################################
resource "aws_sns_topic" "failover_topic" {
  name = "eu-failover-topic"
}

#############################################################
# CloudWatch Alarm for ALB -> triggers SNS
# (HealthyHostCount <1 for 1 data point of 30s => ALARM)
#############################################################
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_alarm" {
  alarm_name          = "alb-0-healthy-hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 30
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Triggers when ALB has 0 healthy hosts for 60s"
# Force 'missing' data to be treated as ALARM
  treat_missing_data  = "breaching"
  
  alarm_actions = [
    aws_sns_topic.failover_topic.arn
  ]

  # Use the ALB + TG arn_suffix from your alb_acm.tf
  dimensions = {
    LoadBalancer = aws_lb.wp_alb.arn_suffix
    TargetGroup  = aws_lb_target_group.wp_tg.arn_suffix
  }

  depends_on = [
    aws_lb.wp_alb,
    aws_lb_target_group.wp_tg
  ]
}

#############################################################
# Automatically subscribe the US Lambda to the EU SNS topic
#############################################################
resource "aws_sns_topic_subscription" "us_lambda_sub" {
  # If the user didn't provide a us_lambda_arn, count=0 => subscription isn't created.
  count = var.us_lambda_arn == "" ? 0 : 1
  
  topic_arn = aws_sns_topic.failover_topic.arn
  protocol  = "lambda"
  endpoint  = var.us_lambda_arn  # The US Lambda's ARN

  # If you see any cross-region issues, you can add:
  # confirmation_timeout_in_minutes = 5
}

#############################################################
# Output the SNS ARN if you need it in the US stack
#############################################################
output "sns_topic_arn" {
  description = "The ARN of the EU SNS topic used for failover"
  value       = aws_sns_topic.failover_topic.arn
}

