variable "name" {
  description = "Name prefix for VPC endpoint resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of private subnets"
  type        = list(string)
}

variable "private_route_table_ids" {
  description = "IDs of private route tables associated with private subnets"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of security group attached to interface VPC endpoints"
  type        = string
}

variable "tags" {
  description = "Tags applied to endpoint resources"
  type        = map(string)
  default     = {}
}
