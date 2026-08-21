variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"

  validation {
    condition     = can(regex("^t[23]\\.(nano|micro|small|medium)$", var.instance_type))
    error_message = "Only t2/t3 nano|micro|small|medium are allowed in the sandbox."
  }
}
