##############################################################################
# IL/failover_lambda.tf
##############################################################################

############################
# Input variable for the EU SNS ARN
############################
variable "eu_sns_topic_arn" {
  type        = string
  description = "The ARN of the SNS topic in EU that triggers this Lambda"
}

############################
# IAM Role & Inline Policy for Lambda
############################
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
  name               = "promote-il-replica-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda_policy_doc" {
  statement {
    sid       = "PromoteReplica"
    actions   = ["rds:PromoteReadReplica"]
    resources = ["*"]
  }

  statement {
    sid       = "Logging"
    actions   = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "promote_replica_lambda_policy" {
  name   = "promote-il-replica-lambda-inline"
  role   = aws_iam_role.promote_replica_lambda_role.id
  policy = data.aws_iam_policy_document.lambda_policy_doc.json
}

############################
# Zip the existing promote_replica.py file
############################
resource "null_resource" "zip_promote_lambda" {
  provisioner "local-exec" {
    # We zip "promote_replica.py" into "function.zip" (both in path.module)
    command = "zip ${path.module}/function.zip ${path.module}/promote_replica.py"
  }

  # Re-run if the .py changes
  triggers = {
    code_hash = filebase64sha256("${path.module}/promote_replica.py")
  }
}

############################
# Create the Lambda
############################
resource "aws_lambda_function" "promote_replica_lambda" {
  function_name = "PromoteILReplica"
  runtime       = "python3.9"
  handler       = "promote_replica.lambda_handler"
  role          = aws_iam_role.promote_replica_lambda_role.arn

  filename         = "${path.module}/function.zip"
  source_code_hash = filebase64sha256("${path.module}/promote_replica.py")

  # Make sure the zip is created first
  depends_on = [null_resource.zip_promote_lambda]
}

############################
# Permission: let EU SNS invoke it
############################
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.promote_replica_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.eu_sns_topic_arn
}

############################
# Output the Lambda ARN (optional)
############################
output "il_lambda_arn" {
  description = "ARN of the IL failover Lambda"
  value       = aws_lambda_function.promote_replica_lambda.arn
}

