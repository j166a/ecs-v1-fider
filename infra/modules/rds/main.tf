resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-db-subnet-group"
    }
  )
}

resource "aws_db_instance" "this" {
  # checkov:skip=CKV2_AWS_30:Full PostgreSQL query logging is not enabled for this development project

  identifier = "${var.name}-postgres"

  engine         = "postgres"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username

  manage_master_user_password = true
  auto_minor_version_upgrade  = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.security_group_id]

  publicly_accessible = false
  skip_final_snapshot = true

  backup_retention_period = 1
  deletion_protection     = false
  apply_immediately       = true
  copy_tags_to_snapshot   = true

  performance_insights_enabled = true

  enabled_cloudwatch_logs_exports = [
    "postgresql",
    "upgrade",
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-postgres"
    }
  )
}
