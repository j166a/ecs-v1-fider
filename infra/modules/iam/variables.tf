variable "name" {
  description = "Name prefix for IAM resources"
  type        = string
}

variable "tags" {
  description = "Tags applied to IAM resources"
  type        = map(string)
  default     = {}
}

variable "ses_identity_arn" {
  description = "ARN of the verified SES identity used by Fider"
  type        = string
}
