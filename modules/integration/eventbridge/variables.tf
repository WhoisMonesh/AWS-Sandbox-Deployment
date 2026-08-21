variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "rule_name" {
  type    = string
  default = "kk-eventbridge"
}

variable "schedule_expression" {
  type    = string
  default = "rate(1 hour)"
}
