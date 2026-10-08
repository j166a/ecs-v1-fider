
resource "aws_secretsmanager_secret" "jwt_secret" {
  name = "/fider/${var.environment}/jwt-secret"

  tags = var.tags
}
