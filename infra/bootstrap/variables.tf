variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform remote state"
  type        = string
}

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
}

variable "github_owner_id" {
  description = "Immutable GitHub repository owner ID"
  type        = number
}

variable "github_repository" {
  description = "GitHub repository name"
  type        = string
}

variable "github_repository_id" {
  description = "Immutable GitHub repository ID"
  type        = number
}
