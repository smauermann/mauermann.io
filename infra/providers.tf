terraform {
  backend "remote" {
    organization = "this"

    workspaces {
      name = "mauermann-io"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.7.0"
    }
  }
}

provider "aws" {
  alias  = "prod"
  region = var.region

  allowed_account_ids = [var.prod_env.account_id]
  assume_role {
    role_arn = "arn:aws:iam::${var.prod_env.account_id}:role/${var.prod_env.role_name}"
  }
}

provider "aws" {
  alias  = "dev"
  region = var.region

  allowed_account_ids = [var.dev_env.account_id]
  assume_role {
    role_arn = "arn:aws:iam::${var.dev_env.account_id}:role/${var.dev_env.role_name}"
  }
}

provider "cloudflare" {}
