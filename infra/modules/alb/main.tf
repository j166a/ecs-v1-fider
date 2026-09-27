resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-alb"
    }
  )
}

resource "aws_lb_target_group" "this" {
  name        = "${var.name}-alb-target-group"
  port        = var.target_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/_health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-alb-target-group"
    }
  )
}
