terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      # Non serve specificare la versione qui, la eredita dalla root
    }
  }
}