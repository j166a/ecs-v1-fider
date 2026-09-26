variable "name" {
  description = "Name prefix for RDS resources"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the RDS subnet group"
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to RDS resources"
  type        = map(string)
  default     = {}
}
