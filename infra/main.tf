locals {
  name = "fider"

  common_tags = {
    Project     = "fider"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source = "./modules/vpc"

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
