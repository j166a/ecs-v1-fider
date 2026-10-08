output "state_bucket_name" {
  description = "S3 bucket used for Terraform remote state"
  value       = aws_s3_bucket.state.bucket
}

output "aws_region" {
  description = "AWS region used by the state bootstrap"
  value       = var.aws_region
}
