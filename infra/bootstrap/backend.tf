terraform {
  backend "s3" {
    key          = "fider/bootstrap/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
