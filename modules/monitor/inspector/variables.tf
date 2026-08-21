variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "resource_types" {
  description = "Inspector2 resource types to enable"
  type        = list(string)
  default     = ["EC2", "ECR"]
}
