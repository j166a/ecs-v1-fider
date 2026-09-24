terraform {
  backend "s3" {
    bucket       = "imadahmed-fider-terraform-state"
    key          = "fider/prod/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}
