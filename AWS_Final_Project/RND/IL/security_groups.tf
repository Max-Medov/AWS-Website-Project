##########################################################
# security_groups.tf
##########################################################
# 1) ALB Security Group
##########################################################
resource "aws_security_group" "alb_sg" {
  name        = "ALB-SG"
  description = "Allow inbound HTTP/HTTPS from the internet"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RND-ALB-SG"
  }
}

##########################################################
# 2) ECS Tasks Security Group
##########################################################
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "ECS-Tasks-SG"
  description = "Allow inbound from ALB on port 80"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RND-ECS-Tasks-SG"
  }
}

##########################################################
# 3) RDS Security Group
##########################################################
resource "aws_security_group" "rds_sg" {
  name        = "RDS-SG"
  description = "Allow MySQL from ECS Tasks only"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "MySQL from ECS tasks"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RND-RDS-SG"
  }
}

