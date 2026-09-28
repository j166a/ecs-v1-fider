locals {
  name = "fider-${var.environment}"

  common_tags = {
    Project     = "fider"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name = local.name
  tags = local.common_tags

  vpc_cidr           = var.vpc_cidr
  availability_zones = ["eu-west-2a", "eu-west-2b"]
}

module "endpoints" {
  source = "../../modules/endpoints"

  name                    = local.name
  tags                    = local.common_tags
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  private_route_table_ids = module.vpc.private_route_table_ids
  security_group_id       = module.security.endpoints_security_group_id
}

module "security" {
  source = "../../modules/security"

  name   = local.name
  tags   = local.common_tags
  vpc_id = module.vpc.vpc_id
}

module "iam" {
  source = "../../modules/iam"

  name = local.name
  tags = local.common_tags

  ses_identity_arn = var.ses_identity_arn

  ssm_parameter_arns = [
    module.ssm.jwt_secret_arn,
  ]

  rds_secret_arn = module.rds.master_user_secret_arn
}

module "ssm" {
  source = "../../modules/ssm"

  environment = var.environment
  jwt_secret  = var.jwt_secret
  tags        = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  name               = local.name
  tags               = local.common_tags
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.security.rds_security_group_id
}

module "alb" {
  source = "../../modules/alb"

  name              = local.name
  public_subnet_ids = module.vpc.public_subnet_ids
  security_group_id = module.security.alb_security_group_id
  vpc_id            = module.vpc.vpc_id
  certificate_arn   = module.acm.certificate_arn
  tags              = local.common_tags
}

module "acm" {
  source = "../../modules/acm"

  domain_name = var.domain_name
  tags        = local.common_tags
}

module "route53" {
  source = "../../modules/route53"

  zone_id      = var.route53_zone_id
  record_name  = var.domain_name
  alb_dns_name = module.alb.dns_name
  alb_zone_id  = module.alb.zone_id
}

data "aws_ecr_repository" "fider" {
  name = "fider"
}

module "ecs" {
  source = "../../modules/ecs"

  name               = local.name
  region             = var.aws_region
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn
  jwt_secret_arn     = module.ssm.jwt_secret_arn
  base_url           = var.base_url
  email_noreply      = var.email_noreply

  image_uri = "${data.aws_ecr_repository.fider.repository_url}:${var.image_tag}"

  private_subnet_ids    = module.vpc.private_subnet_ids
  ecs_security_group_id = module.security.ecs_security_group_id
  target_group_arn      = module.alb.target_group_arn

  db_host       = module.rds.endpoint
  db_name       = module.rds.db_name
  db_username   = module.rds.username
  db_secret_arn = module.rds.master_user_secret_arn

  tags = local.common_tags
}
