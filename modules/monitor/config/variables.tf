variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "random_suffix" {
  description = "Random suffix to guarantee a unique bucket name"
  type        = string
  default     = "0000"
}

variable "recorder_name" {
  description = "Name of the AWS Config configuration recorder and delivery channel"
  type        = string
  default     = "kk-lab-config"
}
