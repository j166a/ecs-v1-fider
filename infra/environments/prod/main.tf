locals {
  name = "fider"

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

  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["eu-west-2a", "eu-west-2b"]

  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24",
  ]

  private_subnet_cidrs = [
    "10.0.3.0/24",
    "10.0.4.0/24",
  ]
}

module "endpoints" {
  source = "../../modules/endpoints"

  name                    = local.name
  tags                    = local.common_tags
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  private_route_table_ids = module.vpc.private_route_table_ids
}
