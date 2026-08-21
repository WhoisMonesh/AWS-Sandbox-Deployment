variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "ca_type" {
  type    = string
  default = "ROOT"
}

variable "key_algorithm" {
  type    = string
  default = "RSA_2048"
}

variable "signing_algorithm" {
  type    = string
  default = "SHA256WITHRSA"
}
