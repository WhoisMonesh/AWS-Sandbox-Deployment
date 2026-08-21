variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "directory_name" {
  type    = string
  default = "kodekloud.local"
}

variable "directory_password" {
  type      = string
  default   = "D!r3ctory2024"
  sensitive = true
}
