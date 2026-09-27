variable "name" {
  description = "Name prefix for ECS resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to ECS resources"
  type        = map(string)
  default     = {}
}
