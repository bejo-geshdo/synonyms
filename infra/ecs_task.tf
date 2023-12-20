# --- ECS Task Role ---

data "aws_iam_policy_document" "ecs_task_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name_prefix        = "${var.name}-${var.env}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}

resource "aws_iam_role" "ecs_exec_role" {
  name_prefix        = "${var.name}-${var.env}-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}

resource "aws_iam_role_policy_attachment" "ecs_exec_role_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#--- ECS Task Definition ---

resource "aws_ecs_task_definition" "app" {
  family             = "${var.name}-${var.env}-app"
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_exec_role.arn
  network_mode       = "awsvpc"
  cpu                = 512
  memory             = 512

  #TODO change image to the one in repo
  container_definitions = jsonencode([{
    name         = "${var.name}-${var.env}",
    image        = "${aws_ecr_repository.app.repository_url}:latest",
    essential    = true,
    portMappings = [{ containerPort = 80, hostPort = 80 }],

    #Sets the express servers port to port 80
    environment = [
      { name = "PORT", value = "80" }
    ]

    logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-region"        = "eu-central-1",
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name,
        "awslogs-stream-prefix" = "${var.name}-${var.env}"
      }
    },
  }])
}

# --- ECS Service ---

resource "aws_security_group" "ecs_task" {
  name_prefix = "ecs-task-sg-"
  description = "Allow all traffic within the VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "app" {
  name            = "app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1

  network_configuration {
    security_groups = [aws_security_group.ecs_task.id]
    subnets         = aws_subnet.public[*].id
  }

  #Connets the instances to ALB to be able to acces them from the internet
  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "${var.name}-${var.env}"
    container_port   = 80
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    base              = 1
    weight            = 100
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  # lifecycle {
  #   ignore_changes = [desired_count]
  # }
}