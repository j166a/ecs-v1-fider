variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "jwt_secret" {
  description = "JWT secret used by Fider"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags applied to SSM parameters"
  type        = map(string)
  default     = {}
}
