variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "parameter_name" {
  description = "Name of the SSM parameter"
  type        = string
  default     = "/kk-lab/env"
}

variable "parameter_value" {
  description = "Value of the SSM parameter"
  type        = string
  default     = "dev"
}

variable "parameter_type" {
  description = "Type of the SSM parameter"
  type        = string
  default     = "String"
}

variable "document_name" {
  description = "Name of the SSM document"
  type        = string
  default     = "kk-lab-shell"
}
