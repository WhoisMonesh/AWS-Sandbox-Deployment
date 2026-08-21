variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "resource_group_name" {
  description = "Name of the resource group used by Application Insights"
  type        = string
  default     = "kk-lab-appinsights"
}
