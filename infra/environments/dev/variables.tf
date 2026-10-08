variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones used by the environment"
  type        = list(string)
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the environment VPC"
  type        = string
}

variable "jwt_secret" {
  description = "JWT secret used by Fider"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Application domain name"
  type        = string
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  type        = string
}

variable "image_tag" {
  description = "Tag of the Fider image to deploy"
  type        = string
}

variable "base_url" {
  description = "Public base URL for Fider"
  type        = string
}

variable "email_noreply" {
  description = "No-reply email address used by Fider"
  type        = string
}

variable "ecs_desired_count" {
  description = "Desired number of ECS service tasks"
  type        = number
  default     = 0
}
