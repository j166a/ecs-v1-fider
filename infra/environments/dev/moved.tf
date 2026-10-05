moved {
  from = module.ecs.aws_cloudwatch_metric_alarm.cpu_high
  to   = module.observability.aws_cloudwatch_metric_alarm.ecs_cpu_high
}

moved {
  from = module.ecs.aws_cloudwatch_metric_alarm.memory_high
  to   = module.observability.aws_cloudwatch_metric_alarm.ecs_memory_high
}
