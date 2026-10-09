
resource "aws_secretsmanager_secret" "jwt_secret" {
  name                    = "/fider/${var.environment}/jwt-secret"
  recovery_window_in_days = 0

  tags = var.tags
}
