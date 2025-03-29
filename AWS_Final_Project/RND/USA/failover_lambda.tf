##############################################################################
# US/failover_lambda.tf
##############################################################################
# Assumes you have an AWS provider for region = "us-east-1" (or whichever US region)
# in main.tf or elsewhere.

variable "eu_sns_topic_arn" {
  type        = string
  description = "The ARN of the EU SNS topic that triggers this Lambda"
}

##############################################################################
# IAM Role & Inline Policy for the Lambda
##############################################################################
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "promote_replica_lambda_role" {
  name               = "promote-us-replica-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda_policy_doc" {
  statement {
    sid     = "PromoteReplica"
    actions = ["rds:PromoteReadReplica"]
    resources = ["*"]
  }
  statement {
    sid     = "Logging"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "promote_replica_lambda_policy" {
  name   = "promote-us-replica-lambda-inline"
  role   = aws_iam_role.promote_replica_lambda_role.id
  policy = data.aws_iam_policy_document.lambda_policy_doc.json
}

##############################################################################
# Zip the local Python code "promote_replica.py" into "function.zip"
##############################################################################
resource "null_resource" "zip_promote_lambda" {
  provisioner "local-exec" {
    command = "zip ${path.module}/function.zip ${path.module}/promote_replica.py"
  }
  triggers = {
    code_hash = filebase64sha256("${path.module}/promote_replica.py")
  }
}

##############################################################################
# Lambda that calls rds.promote_read_replica
##############################################################################
resource "aws_lambda_function" "promote_replica_lambda" {
  function_name = "PromoteUSReplica"
  runtime       = "python3.9"
  handler       = "promote_replica.lambda_handler"
  role          = aws_iam_role.promote_replica_lambda_role.arn

  filename         = "${path.module}/function.zip"
  source_code_hash = filebase64sha256("${path.module}/promote_replica.py")

  depends_on = [null_resource.zip_promote_lambda]
}

##############################################################################
# Allow the EU SNS topic to invoke this function
##############################################################################
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.promote_replica_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.eu_sns_topic_arn
}

##############################################################################
# Output the Lambda ARN
##############################################################################
output "us_lambda_arn" {
  description = "ARN of the US failover Lambda"
  value       = aws_lambda_function.promote_replica_lambda.arn
}

