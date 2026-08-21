variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "log_group_name" {
  description = "Name of the CloudWatch log group"
  type        = string
  default     = "/kk-lab/app"
}

variable "alarm_name" {
  description = "Name of the dummy CloudWatch metric alarm"
  type        = string
  default     = "kk-lab-dummy-alarm"
}
