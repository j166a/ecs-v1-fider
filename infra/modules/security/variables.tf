variable "name" {
  description = "Name prefix for security group resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "tags" {
  description = "Tags applied to security group resources"
  type        = map(string)
  default     = {}
}
