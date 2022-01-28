locals {
  domain = var.subdomain == "" ? var.zone : join(".", [var.subdomain, var.zone])
}

### S3 Bucket
data "aws_iam_policy_document" "bucket" {
  statement {
    sid = "AllowGetObject"

    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${local.domain}/*"]
    principals {
      identifiers = ["*"]
      type        = "*"
    }
  }
}

resource "aws_s3_bucket" "this" {
  bucket = local.domain
  acl    = "public-read"
  policy = data.aws_iam_policy_document.bucket.json

  website {
    index_document = var.index_document
    error_document = var.error_document
  }
}

### Assuming an IAM role via the GitHub OIDC identity provider in GitHub actions
# https://github.com/aws-actions/configure-aws-credentials#assuming-a-role
# https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services
# https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_oidc.html
resource "aws_iam_openid_connect_provider" "this" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "deploy_trust" {
  statement {
    sid = "TrustGitHubOIDC"

    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      identifiers = [aws_iam_openid_connect_provider.this.arn]
      type        = "Federated"
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_repo}:ref:refs/heads/master",
        "repo:${var.github_repo}:pull_request"
      ]
    }
  }
}

data "aws_iam_policy_document" "deploy_permissions" {
  statement {
    sid = "AllowS3Sync"

    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*"
    ]
  }
}

resource "aws_iam_role" "deploy" {
  name_prefix        = "deploy-s3-static-website"
  assume_role_policy = data.aws_iam_policy_document.deploy_trust.json

  inline_policy {
    name   = "allow-s3-sync"
    policy = data.aws_iam_policy_document.deploy_permissions.json
  }
  lifecycle {
    create_before_destroy = true
  }
}

### Cloudflare Record
data "cloudflare_zone" "this" {
  name = var.zone
}

resource "cloudflare_record" "this" {
  zone_id = data.cloudflare_zone.this.id

  name    = local.domain
  type    = "CNAME"
  value   = aws_s3_bucket.this.website_endpoint
  proxied = true
}
