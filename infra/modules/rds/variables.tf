variable "name" {
  description = "Name prefix for RDS resources"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the RDS subnet group"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID attached to the RDS instance"
  type        = string
}

variable "db_name" {
  description = "Initial PostgreSQL database name"
  type        = string
  default     = "fider"
}

variable "db_username" {
  description = "Master PostgreSQL username"
  type        = string
  default     = "fider"
}

variable "tags" {
  description = "Tags applied to RDS resources"
  type        = map(string)
  default     = {}
}
