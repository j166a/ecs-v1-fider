variable "domain_name" {
  description = "Domain name for the ACM certificate"
  type        = string
}

variable "tags" {
  description = "Tags to apply to ACM resources"
  type        = map(string)
  default     = {}
}
