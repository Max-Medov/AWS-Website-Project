########################################
# ecs_fargate.tf
########################################

data "template_file" "wp_container_def" {
  template = file("${path.module}/wordpress_container.json")
  vars = {
    # Make sure these resource names match your secrets_manager.tf & rds.tf
    secret_arn = aws_secretsmanager_secret.db_secret.arn
    db_host    = aws_db_instance.wp_db.address
    db_port    = aws_db_instance.wp_db.port
  }
}

resource "aws_ecs_cluster" "wp_cluster" {
  name = "wp-rnd-cluster"
}

resource "aws_ecs_cluster_capacity_providers" "wp_cluster_providers" {
  cluster_name       = aws_ecs_cluster.wp_cluster.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}

########################################
# ECS IAM Roles
########################################

resource "aws_iam_role" "ecs_execution_role" {
  name               = "ecsExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_assume_role.json
}

data "aws_iam_policy_document" "ecs_execution_assume_role" {
  statement {
    actions   = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_exec_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_exec_secretsmanager_access" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "ecsTaskRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions   = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ecs_task_secrets_policy" {
  name = "ecsTaskSecretsPolicy"
  role = aws_iam_role.ecs_task_role.id
  policy = data.aws_iam_policy_document.ecs_task_secrets_doc.json
}

data "aws_iam_policy_document" "ecs_task_secrets_doc" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "kms:Decrypt"
    ]
    resources = [
      "${aws_secretsmanager_secret.db_secret.arn}*"
      # If using a custom KMS key for secrets, add key ARN here
    ]
  }
}

########################################
# ECS Task Definition (WordPress)
########################################
resource "aws_ecs_task_definition" "wp_task" {
  family                   = "wp-rnd-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = data.template_file.wp_container_def.rendered

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

########################################
# ECS Service (spread tasks across TWO AZs)
########################################
resource "aws_ecs_service" "wp_service" {
  name            = "wp-service"
  cluster         = aws_ecs_cluster.wp_cluster.id
  task_definition = aws_ecs_task_definition.wp_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = false
    subnets = [
      aws_subnet.private_subnet.id,
      aws_subnet.private_subnet_2.id
    ]
    security_groups = [aws_security_group.ecs_tasks_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.wp_tg.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.wp_https_listener
  ]
}

