module "dev_website" {
  source = "./s3-website-cloudflare"

  zone      = var.zone
  subdomain = "dev"

  github_repo = var.github_repo

  providers = {
    aws = aws.dev
  }
}

module "prod_website" {
  source = "./s3-website-cloudflare"

  zone      = var.zone
  subdomain = "prod"

  github_repo = var.github_repo

  providers = {
    aws = aws.prod
  }
}
