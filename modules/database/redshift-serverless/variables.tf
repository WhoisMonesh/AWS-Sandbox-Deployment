variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "namespace_name" {
  type    = string
  default = "kk-lab-ns"
}

variable "workgroup_name" {
  type    = string
  default = "kk-lab-wg"
}

variable "db_name" {
  type    = string
  default = "kklabdb"
}

variable "admin_username" {
  type      = string
  default   = "kklabadmin"
  sensitive = true
}

variable "admin_password" {
  type      = string
  sensitive = true
  default   = "Kk!Lab#2024pass"
}
