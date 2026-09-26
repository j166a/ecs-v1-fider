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
}

module "ssm" {
  source = "../../modules/ssm"

  environment = var.environment
  jwt_secret  = var.jwt_secret
  tags        = local.common_tags
}
