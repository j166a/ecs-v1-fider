variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "state_bucket_name" {
  description = "S3 bucket used for Terraform remote state"
  type        = string
}
