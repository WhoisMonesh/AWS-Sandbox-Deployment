variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "table_name" {
  type    = string
  default = "kk-lab-table"
}

variable "hash_key" {
  type    = string
  default = "id"
}

variable "billing_mode" {
  type    = string
  default = "PAY_PER_REQUEST"

  validation {
    condition     = var.billing_mode == "PAY_PER_REQUEST"
    error_message = "Sandbox: DynamoDB must use PAY_PER_REQUEST."
  }
}
