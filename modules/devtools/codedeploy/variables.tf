variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "deployment_group_name" {
  type    = string
  default = "kk-codedeploy-dg"
}

variable "ec2_tag_key" {
  type    = string
  default = "Application"
}

variable "ec2_tag_value" {
  type    = string
  default = "kk-lab"
}
