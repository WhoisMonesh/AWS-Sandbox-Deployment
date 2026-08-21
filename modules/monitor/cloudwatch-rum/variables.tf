variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "app_monitor_name" {
  description = "Name of the RUM app monitor"
  type        = string
  default     = "kk-lab-rum"
}

variable "domain" {
  description = "Domain the RUM app monitor will collect data from"
  type        = string
  default     = "example.com"
}
