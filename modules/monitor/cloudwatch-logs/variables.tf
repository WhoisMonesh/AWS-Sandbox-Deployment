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
  default     = "/kk-lab/logs"
}

variable "retention_in_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 7
}
