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
      "arn:aws:s3:::${var.state_bucket_name}",
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
      "arn:aws:s3:::${var.state_bucket_name}/fider/dev/terraform.tfstate",
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
      "arn:aws:s3:::${var.state_bucket_name}/fider/dev/terraform.tfstate.tflock",
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

  # ACM

  statement {
    effect = "Allow"

    actions = [
      "acm:DescribeCertificate",
      "acm:ListTagsForCertificate",
    ]

    resources = [
      "arn:aws:acm:eu-west-2:${data.aws_caller_identity.current.account_id}:certificate/*",
    ]
  }

  # CloudWatch Logs

  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:DescribeAlarms",
      "cloudwatch:ListTagsForResource",
      "logs:DescribeLogGroups",
      "logs:ListTagsForResource",
    ]

    resources = ["*"]
  }

  # EC2 / VPC

  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeManagedPrefixLists",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribePrefixLists",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroupRules",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeVpcs",
    ]

    resources = ["*"]
  }

  # ELBv2

  statement {
    effect = "Allow"

    actions = [
      "elasticloadbalancing:DescribeListenerAttributes",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
    ]

    resources = ["*"]
  }

  # ECS

  statement {
    effect = "Allow"

    actions = [
      "ecs:DescribeClusters",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:ListTagsForResource",
    ]

    resources = ["*"]
  }

  # IAM - Roles

  statement {
    effect = "Allow"

    actions = [
      "iam:GetRole",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:ListRolePolicies",
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/fider-dev-*",
    ]
  }

  # IAM - Managed Policies

  statement {
    effect = "Allow"

    actions = [
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/fider-dev-*",
    ]
  }

  # RDS

  statement {
    effect = "Allow"

    actions = [
      "rds:DescribeDBInstances",
      "rds:DescribeDBSubnetGroups",
      "rds:ListTagsForResource",
    ]

    resources = ["*"]
  }

  # Route 53

  statement {
    effect = "Allow"

    actions = [
      "route53:GetHostedZone",
      "route53:ListResourceRecordSets",
    ]

    resources = ["*"]
  }

  # SSM

  statement {
    effect = "Allow"

    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameter",
      "ssm:ListTagsForResource",
    ]

    resources = ["*"]
  }

  # SNS

  statement {
    effect = "Allow"

    actions = [
      "sns:GetTopicAttributes",
      "sns:ListTagsForResource",
    ]

    resources = [
      "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:fider-dev-alerts"
    ]
  }
}

resource "aws_iam_role_policy" "github_actions_terraform_plan" {
  name   = "fider-github-actions-terraform-plan"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_terraform_plan.json
}
