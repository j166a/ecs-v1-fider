variable "name" {
  description = "Name prefix for observability resources"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster to monitor"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service to monitor"
  type        = string
}

variable "tags" {
  description = "Tags to apply to observability resources"
  type        = map(string)
  default     = {}
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the ALB target group"
  type        = string
}

variable "db_instance_identifier" {
  description = "value"
  type        = string
}
