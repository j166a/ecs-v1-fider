output "private_subnet_ids" {
  description = "Private subnet IDs used by ECS tasks"
  value       = module.vpc.private_subnet_ids
}

output "ecs_security_group_id" {
  description = "Security group ID attached to ECS tasks"
  value       = module.security.ecs_security_group_id
}

output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs.cluster_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.service_name
}

output "ecs_task_definition_family" {
  description = "Family of the ECS task definition"
  value       = module.ecs.task_definition_family
}
