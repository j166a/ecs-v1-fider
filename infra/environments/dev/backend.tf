terraform {
  backend "s3" {
    key          = "fider/dev/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
