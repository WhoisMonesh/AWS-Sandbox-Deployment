variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "rule_name" {
  description = "Name of the X-Ray sampling rule"
  type        = string
  default     = "kk-lab-rule"
}

variable "fixed_rate" {
  description = "Fixed sampling rate between 0 and 1"
  type        = number
  default     = 0.05

  validation {
    condition     = var.fixed_rate >= 0 && var.fixed_rate <= 1
    error_message = "fixed_rate must be between 0 and 1."
  }
}
