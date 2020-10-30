terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.1"
    }
    template = {
      source  = "hashicorp/template"
      version = ">= 2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 1.2"
    }
    null = {
      source  = "hashicorp/local"
      version = ">= 2.0"
    }
  }
}
