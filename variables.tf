variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "keybase_verification_code" {
  description = "Keybase verification code for domain ownership"
  type        = string
  sensitive   = true
}