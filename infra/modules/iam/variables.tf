variable "name" {
  description = "Name prefix for IAM resources"
  type        = string
}

variable "tags" {
  description = "Tags applied to IAM resources"
  type        = map(string)
  default     = {}
}

variable "ssm_parameter_arns" {
  description = "ARNs of SSM paramters the ECS execution role may retrieve"
  type        = list(string)
  default     = []
}

variable "rds_secret_arn" {
  description = "ARN of the RDS-managed Secrets Manager secret"
  type        = string
}

variable "ses_from_address" {
  description = "Email address Fider is allowed to use as the SES From address"
  type        = string
}
