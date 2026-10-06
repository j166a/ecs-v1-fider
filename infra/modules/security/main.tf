resource "aws_security_group" "alb" {
  # checkov:skip=CKV2_AWS_5:Attached to the ALB through the ALB module
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

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  # checkov:skip=CKV_AWS_260:Port 80 is required only to redirect HTTP to HTTPS
  security_group_id = aws_security_group.alb.id
  description       = "Allow public HTTP for redirect to HTTPS"

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow public HTTPS traffic"

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow ALB traffic to ECS tasks"

  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 3000
  ip_protocol                  = "tcp"
  to_port                      = 3000
}

resource "aws_security_group" "ecs" {
  # checkov:skip=CKV2_AWS_5:Attached to the ECS through the ECS module
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

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id = aws_security_group.ecs.id
  description       = "Allow ECS traffic from ALB"

  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 3000
  ip_protocol                  = "tcp"
  to_port                      = 3000
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_rds" {
  security_group_id = aws_security_group.ecs.id
  description       = "Allow ECS access to PostgreSQL"

  referenced_security_group_id = aws_security_group.rds.id
  from_port                    = 5432
  ip_protocol                  = "tcp"
  to_port                      = 5432
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_endpoints" {
  security_group_id = aws_security_group.ecs.id
  description       = "Allow ECS access to VPC endpoints"

  referenced_security_group_id = aws_security_group.endpoints.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}

data "aws_region" "current" {}

data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${data.aws_region.current.region}.s3"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_s3" {
  security_group_id = aws_security_group.ecs.id
  description       = "Allow ECS access to S3"

  prefix_list_id = data.aws_prefix_list.s3.id
  from_port      = 443
  ip_protocol    = "tcp"
  to_port        = 443
}

resource "aws_security_group" "rds" {
  # checkov:skip=CKV2_AWS_5:Attached to the RDS through the RDS module
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

resource "aws_vpc_security_group_ingress_rule" "rds_from_ecs" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow PostgreSQL traffic from ECS"

  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 5432
  ip_protocol                  = "tcp"
  to_port                      = 5432
}

resource "aws_vpc_security_group_ingress_rule" "endpoints_from_ecs" {
  security_group_id = aws_security_group.endpoints.id
  description       = "Allow HTTPS from ECS to VPC endpoints"

  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}

resource "aws_security_group" "endpoints" {
  # checkov:skip=CKV2_AWS_5:Attached to the endpoints through the endpoints module
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
