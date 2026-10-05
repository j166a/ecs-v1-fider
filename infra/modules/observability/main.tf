resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name        = "${var.name}-cpu-high"
  alarm_description = "ECS service CPU utilisation is above 80%"

  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  treat_missing_data = "notBreaching"

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name        = "${var.name}-memory-high"
  alarm_description = "ECS service memory utilisation is above 80%"

  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  treat_missing_data = "notBreaching"

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_targets" {
  alarm_name        = "${var.name}-alb-unhealthy-targets"
  alarm_description = "ALB has one or more unhealthy targets"

  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  treat_missing_data = "notBreaching"

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name        = "${var.name}-alb-5xx"
  alarm_description = "ALB is returning HTTP 5xx responses"

  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 2
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  treat_missing_data = "notBreaching"

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name        = "${var.name}-rds-cpu-high"
  alarm_description = "RDS CPU utilisation is above 80%"

  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  treat_missing_data = "notBreaching"

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
  alarm_name        = "${var.name}-rds-free-storage-low"
  alarm_description = "RDS free storage is below 2 GiB"

  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 2147483648 # 2 GiB in bytes (2 x 1,024^3)
  comparison_operator = "LessThanThreshold"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  treat_missing_data = "notBreaching"

  tags = var.tags
}
