resource "aws_ecs_cluster" "this" {
  name = "${var.name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-cluster"
    }
  )
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name}"
  retention_in_days = 7

  tags = var.tags
}

resource "aws_ecs_task_definition" "this" {
  family = "${var.name}-task-definition"

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = var.name
      image     = var.image_uri
      essential = true

      portMappings = [{
        containerPort = 3000
        protocol      = "tcp"
      }]

      environment = [
        { name = "DB_HOST", value = var.db_host },
        { name = "DB_NAME", value = var.db_name },
        { name = "DB_USERNAME", value = var.db_username },
        { name = "BASE_URL", value = var.base_url },
        { name = "EMAIL_TYPE", value = var.email_type },
        { name = "EMAIL_NOREPLY", value = var.email_noreply },
        { name = "EMAIL_AWSSES_REGION", value = var.region }
      ]

      secrets = [
        { name = "DB_PASSWORD", valueFrom = "${var.db_secret_arn}:password::" },
        { name = "JWT_SECRET", valueFrom = var.jwt_secret_arn }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = var.region
          awslogs-stream-prefix = var.name
        }
      }

      healthCheck = {
        command     = ["CMD", "/app/fider", "ping"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = var.tags
}

resource "aws_ecs_service" "this" {
  name            = "${var.name}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  health_check_grace_period_seconds = 60

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.name
    container_port   = 3000
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = var.tags
}
