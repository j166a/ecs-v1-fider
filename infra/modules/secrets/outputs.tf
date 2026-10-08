output "jwt_secret_arn" {
  description = "ARN of the Fider JWT secret"
  value       = aws_secretsmanager_secret.jwt_secret.arn
}
