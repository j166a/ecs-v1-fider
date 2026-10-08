variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "tags" {
  description = "Tags applied to Secrets Manager secrets"
  type        = map(string)
  default     = {}
}
