data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_execution" {
  name               = "${var.name}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  name               = "${var.name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  tags = var.tags
}

data "aws_iam_policy_document" "ecs_task_ses" {
  statement {
    effect = "Allow"

    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail",
    ]

    resources = [var.ses_identity_arn]
  }

  statement {
    actions   = ["ses:ListSuppressedDestinations"]
    resources = ["*"]
  }

}

resource "aws_iam_policy" "ecs_task_ses" {
  name   = "${var.name}-task-ses"
  policy = data.aws_iam_policy_document.ecs_task_ses.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_ses" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_task_ses.arn
}

data "aws_iam_policy_document" "ecs_execution_ssm" {
  statement {
    effect = "Allow"

    actions = [
      "ssm:GetParameters",
    ]

    resources = var.ssm_parameter_arns
  }
}

resource "aws_iam_policy" "ecs_execution_ssm" {
  name   = "${var.name}-execution-ssm"
  policy = data.aws_iam_policy_document.ecs_execution_ssm.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution_ssm" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = aws_iam_policy.ecs_execution_ssm.arn
}

data "aws_iam_policy_document" "ecs_execution_secrets" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      var.rds_secret_arn
    ]
  }
}

resource "aws_iam_policy" "ecs_execution_secrets" {
  name   = "${var.name}-execution-secrets"
  policy = data.aws_iam_policy_document.ecs_execution_secrets.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution_secrets" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = aws_iam_policy.ecs_execution_secrets.arn
}
