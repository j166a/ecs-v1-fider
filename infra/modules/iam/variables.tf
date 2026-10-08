variable "name" {
  description = "Name prefix for IAM resources"
  type        = string
}

variable "tags" {
  description = "Tags applied to IAM resources"
  type        = map(string)
  default     = {}
}

variable "secret_arns" {
  description = "Secrets Manager ARNs accessible to the ECS execution role"
  type        = list(string)
}

variable "ses_from_address" {
  description = "Email address Fider is allowed to use as the SES From address"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository the ECS execution role may pull from"
  type        = string
}
