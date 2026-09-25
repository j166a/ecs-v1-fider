resource "aws_ssm_parameter" "jwt_secret" {
  name  = "/fider/${var.environment}/jwt-secret"
  type  = "SecureString"
  value = var.jwt_secret

  tags = var.tags
}
