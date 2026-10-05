output "endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "RDS PostgreSQL port"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "RDS PostgreSQL database name"
  value       = aws_db_instance.this.db_name
}

output "db_instance_identifier" {
  description = "Instance identifier of the RDS PostgreSQL database"
  value       = aws_db_instance.this.identifier
}

output "username" {
  description = "Master PostgreSQL username"
  value       = aws_db_instance.this.username
}

output "master_user_secret_arn" {
  description = "ARN of the RDS managed master user secret"
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}
