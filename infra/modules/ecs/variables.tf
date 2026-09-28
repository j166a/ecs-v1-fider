variable "name" {
  description = "Name prefix for ECS resources"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the ECS task execution role used by the task definition"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the ECS task role used by the task definition"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "image_uri" {
  description = "URI of the app image from ECR"
  type        = string
}

variable "db_host" {
  description = "RDS PostgreSQL database endpoint"
  type        = string
}

variable "db_name" {
  description = "RDS PostgreSQL database name"
  type        = string
}

variable "db_username" {
  description = "RDS PostgreSQL database username"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of the RDS managed master user secret"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}


variable "base_url" {
  description = "Public base URL for Fider"
  type        = string
}

variable "email_noreply" {
  description = "No-reply email address used by Fider"
  type        = string
}


variable "tags" {
  description = "Tags to apply to ECS resources"
  type        = map(string)
  default     = {}
}
