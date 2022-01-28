variable "dev_env" {
  type = object({
    account_id = string
    role_name  = string
  })
}

variable "prod_env" {
  type = object({
    account_id = string
    role_name  = string
  })
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "github_repo" {
  type = string
}
