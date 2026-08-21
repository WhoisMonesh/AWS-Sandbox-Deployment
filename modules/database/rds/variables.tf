variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "engine" {
  type    = string
  default = "mysql"

  validation {
    condition     = contains(["mysql", "mariadb", "postgres"], var.engine)
    error_message = "Allowed engines: mysql, mariadb, postgres."
  }
}

variable "instance_class" {
  type    = string
  default = "db.t3.micro"

  validation {
    condition     = can(regex("^db\\.t[234g]\\.(nano|micro|small|medium)$", var.instance_class))
    error_message = "Only db.t* nano|micro|small|medium allowed in the sandbox."
  }
}

variable "db_username" {
  type      = string
  default   = "kklabadmin"
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
  default   = "Kk!Lab#2024pass"
}

variable "allocated_storage" {
  type    = number
  default = 20
}
