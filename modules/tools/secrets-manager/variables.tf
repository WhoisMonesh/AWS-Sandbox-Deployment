variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "secret_password" {
  type      = string
  default   = "Sup3rS3cret2024!"
  sensitive = true
}
