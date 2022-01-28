variable "subdomain" {
  type    = string
  default = ""
}

variable "zone" {
  type = string
}

variable "index_document" {
  type    = string
  default = "index.html"
}

variable "error_document" {
  type    = string
  default = "404.html"
}

variable "github_repo" {
  type = string
}
