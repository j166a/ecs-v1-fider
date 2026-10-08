output "state_bucket_name" {
  description = "S3 bucket used for Terraform remote state"
  value       = var.state_bucket_name
}

output "ecr_repository_url" {
  description = "ECR repository URL for Fider images"
  value       = aws_ecr_repository.fider.repository_url
}

output "aws_region" {
  description = "AWS region used by the bootstrap infrastructure"
  value       = var.aws_region
}
