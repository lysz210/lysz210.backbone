terraform {
  required_version = ">= 1.0"
  cloud {
    organization = "lysz210"

    workspaces {
      name = "lysz210-backbone"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

# Provider principale (es. Irlanda)
provider "aws" {
  region = "eu-west-1"
}

# Provider secondario per risorse globali (Certificati e DNSSEC)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "github" {
  token = var.github_token
}