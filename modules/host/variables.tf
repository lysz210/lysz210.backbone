variable "app_name" {
  description = "The name of the application."
  type        = string
}

variable "domain_name" {
  description = "The domain name for the application."
  type        = string
}

variable "github_owner" {
  description = "The GitHub owner for the application."
  type        = string
}

variable "github_repo" {
  description = "The GitHub repo name"
  type        = string
}

variable "aws_oidc_arn" {
  description = "The ARN of the AWS OIDC Provider for GitHub Actions."
  type        = string
}

variable "aws_route53_zone_id" {
  description = "The Route 53 Hosted Zone ID for the domain."
  type        = string
}

variable "aws_cert_arn" {
  description = "The ARN of the ACM Certificate for the domain."
  type        = string
}