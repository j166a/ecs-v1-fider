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
      "ecr:DescribeImages",
      "ecr:ListTagsForResource",
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

data "aws_iam_policy_document" "github_actions_deploy_assume_role" {
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
        "repo:${var.github_owner}@${var.github_owner_id}/${var.github_repository}@${var.github_repository_id}:environment:dev",
      ]
    }
  }
}

resource "aws_iam_role" "github_actions_deploy" {
  name               = "fider-github-actions-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_actions_deploy_assume_role.json
}

resource "aws_iam_role_policy" "github_actions_deploy_backend" {
  name   = "fider-github-actions-deploy-backend"
  role   = aws_iam_role.github_actions_deploy.id
  policy = data.aws_iam_policy_document.github_actions_terraform_plan.json
}

data "aws_caller_identity" "current" {}
locals {
  dev_name = "fider-dev"
}

data "aws_iam_policy_document" "github_actions_deploy_infrastructure" {
  statement {
    effect = "Allow"

    actions = [
      "acm:RequestCertificate",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "acm:AddTagsToCertificate",
      "acm:DescribeCertificate",
      "acm:ListTagsForCertificate",
    ]

    resources = [
      "arn:aws:acm:eu-west-2:${data.aws_caller_identity.current.account_id}:certificate/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecs:CreateCluster",
      "ecs:TagResource",
      "ecs:DescribeClusters",
    ]

    resources = [
      "arn:aws:ecs:eu-west-2:${data.aws_caller_identity.current.account_id}:cluster/${local.dev_name}-cluster",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
    ]

    resources = [
      "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:/ecs/fider-dev",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "iam:CreateRole",
      "iam:TagRole",
      "iam:GetRole",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/fider-dev-*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "iam:CreatePolicy",
      "iam:TagPolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/fider-dev-*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ssm:PutParameter",
      "ssm:AddTagsToResource",
      "ssm:GetParameter",
      "ssm:ListTagsForResource",
    ]

    resources = [
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/fider/dev/jwt-secret",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ssm:DescribeParameters",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateVpc",
      "ec2:CreateTags",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcAttribute",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_actions_deploy_infrastructure" {
  name   = "fider-github-actions-deploy-infrastructure"
  role   = aws_iam_role.github_actions_deploy.id
  policy = data.aws_iam_policy_document.github_actions_deploy_infrastructure.json
}
