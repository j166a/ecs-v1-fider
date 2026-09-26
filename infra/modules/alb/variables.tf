variable "name" {
  description = "Name prefix of ALB resources"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the Application Load Balancer"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID attached to the Application Load Balancer"
  type        = string
}

variable "tags" {
  description = "Tags applied to ALB resources"
  type        = map(string)
  default     = {}
}
