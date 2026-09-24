resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-alb-sg"
    }
  )
}

resource "aws_security_group" "ecs" {
  name        = "${var.name}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-ecs-sg"
    }
  )
}

resource "aws_security_group" "rds" {
  name        = "${var.name}-rds-sg"
  description = "Security group for RDS"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-rds-sg"
    }
  )
}

resource "aws_security_group" "endpoints" {
  name        = "${var.name}-endpoints-sg"
  description = "Security group for VPC interface endpoints"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-endpoints-sg"
    }
  )
}
