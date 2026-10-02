resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.github.arn,
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"

      values = [
        "sts.amazonaws.com",
      ]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "repo:${var.github_owner}@${var.github_owner_id}/${var.github_repository}@${var.github_repository_id}:*",
      ]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "fider-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

data "aws_iam_policy_document" "github_actions_ecr" {
  statement {
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]

    resources = [
      aws_ecr_repository.fider.arn,
    ]
  }
}

resource "aws_iam_role_policy" "github_actions_ecr" {
  name   = "fider-github-actions-ecr"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_ecr.json
}

data "aws_iam_policy_document" "github_actions_terraform_plan" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.state.arn,
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"

      values = [
        "fider/dev/*",
      ]
    }
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.state.arn}/fider/dev/terraform.tfstate",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = [
      "${aws_s3_bucket.state.arn}/fider/dev/terraform.tfstate.tflock",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecr:DescribeRepositories",
    ]

    resources = [
      aws_ecr_repository.fider.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribePrefixLists",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_actions_terraform_plan" {
  name   = "fider-github-actions-terraform-plan"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_terraform_plan.json
}
