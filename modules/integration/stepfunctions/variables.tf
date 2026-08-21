variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "state_machine_name" {
  type    = string
  default = "kk-stepfunctions"
}
