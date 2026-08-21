variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "domain_name" {
  type    = string
  default = "kk-domain"
}

variable "repository_name" {
  type    = string
  default = "kk-repo"
}

variable "repository_format" {
  type    = string
  default = "generic"
}
