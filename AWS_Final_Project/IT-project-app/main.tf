########################################################
# main.tf
# References:
#   - userdata.tpl for EC2 user data
#   - lambda_query.zip for the Lambda code
########################################################

provider "aws" {
  region  = "us-east-2"
  profile = var.aws_profile
}

########################################################
# Variables (for reference; you can define them in variables.tf)
########################################################
/*
variable "aws_profile" {
  type = string
}

variable "alb_domain_name" {
  type        = string
  description = "Domain for ALB's ACM certificate"
}
*/

########################################################
# 1) Create an ACM certificate for ALB (DNS validation)
########################################################
resource "aws_acm_certificate" "alb_cert" {
  domain_name       = var.alb_domain_name
  validation_method = "DNS"
}

# Output the DNS validation details for you to manually create the CNAME
output "acm_dns_validation" {
  description = "DNS validation details"
  value       = tolist(aws_acm_certificate.alb_cert.domain_validation_options)[0]
}

########################################################
# 2) Data lookups for VPC, subnets
########################################################
data "aws_vpc" "it_vpc" {
  tags = { Name = "Lovely-IT-DevOps-VPC-US" }
}

data "aws_subnets" "private_subnets" {
  filter {
    name   = "tag:Name"
    values = ["Private-Subnet-US*", "Private-Subnet-US-2*"]
  }
}

data "aws_subnets" "public_subnets" {
  filter {
    name   = "tag:Name"
    values = ["Public-Subnet-US*", "Public-Subnet-US-2*"]
  }
}

########################################################
# 3) Security Groups
########################################################

# ALB SG
resource "aws_security_group" "alb_sg" {
  name        = "IT-ALB-SG"
  description = "Allow inbound HTTPS from anywhere"
  vpc_id      = data.aws_vpc.it_vpc.id

  ingress {
    description = "Allow HTTPS from anywhere"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 SG
resource "aws_security_group" "ec2_sg" {
  name        = "IT-Flask-EC2-SG"
  description = "Allow inbound from ALB to port 3000"
  vpc_id      = data.aws_vpc.it_vpc.id

  ingress {
    description     = "Inbound from ALB on port 3000"
    protocol        = "tcp"
    from_port       = 3000
    to_port         = 3000
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allow all outbound"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########################################################
# 4) ALB with HTTPS
########################################################
resource "aws_lb" "app_alb" {
  name               = "IT-App-ALB"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.public_subnets.ids
}

resource "aws_lb_target_group" "app_tg" {
  name     = "IT-Flask-TG"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.it_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    healthy_threshold   = 3
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "alb_https_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.alb_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

########################################################
# 5) IAM for EC2
########################################################
resource "aws_iam_role" "ec2_role" {
  name = "IT-EC2-Flask-Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action   = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "dynamodb_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "IT-EC2-Flask-Profile"
  role = aws_iam_role.ec2_role.name
}

########################################################
# 6) DynamoDB Table (Optional)
########################################################
resource "aws_dynamodb_table" "user_details" {
  name         = "UserDetails"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "SerialNumber"

  attribute {
    name = "SerialNumber"
    type = "S"
  }
}

########################################################
# 7) Two EC2 Instances with user_data.tpl
########################################################

data "aws_ssm_parameter" "amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "flask_instances" {
  count                  = 2
  ami                    = data.aws_ssm_parameter.amazon_linux.value
  instance_type          = "t3.micro"
  subnet_id              = element(data.aws_subnets.private_subnets.ids, count.index)
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = templatefile("${path.module}/userdata.tpl", {
    bucket_name    = "lovely-company-files-maxmedov",
    dynamodb_table = aws_dynamodb_table.user_details.name
    kms_key_arn   = var.kms_key_arn
  })

  tags = {
    Name = "IT-Flask-Instance-${count.index + 1}"
  }
}

resource "aws_lb_target_group_attachment" "tg_attach" {
  count            = 2
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.flask_instances[count.index].id
  port             = 3000
}

########################################################
# 8) Lambda + API Gateway referencing "lambda_query.zip" 
#    if needed. (Omitted if you don't want in same file)
########################################################
# (You can add from your old code)

########################################################
# 9) Outputs
########################################################
output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.app_alb.dns_name
}

output "dynamodb_table_name" {
  description = "DynamoDB Table for user details"
  value       = aws_dynamodb_table.user_details.name
}

