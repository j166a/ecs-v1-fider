data "aws_iam_policy_document" "github_actions_app_deploy" {
  statement {
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeImages",
    ]

    resources = [
      aws_ecr_repository.fider.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:RegisterTaskDefinition",
      "ecs:RunTask",
      "ecs:UpdateService",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "iam:PassRole",
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/fider-dev-execution-role",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/fider-dev-task-role",
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"

      values = [
        "ecs-tasks.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "github_actions_app_deploy" {
  name               = "fider-github-actions-app-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_actions_dev_environment_assume_role.json
}

resource "aws_iam_role_policy" "github_actions_app_deploy" {
  name   = "fider-github-actions-app-deploy"
  role   = aws_iam_role.github_actions_app_deploy.id
  policy = data.aws_iam_policy_document.github_actions_app_deploy.json
}
