output "jwt_secret_arn" {
  description = "ARN of the Fider JWT secret parameter"
  value       = aws_ssm_parameter.jwt_secret.arn
}
