variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "function_name" {
  type    = string
  default = "kk-lab-fn"
}

variable "runtime" {
  type    = string
  default = "python3.12"
}

variable "handler" {
  type    = string
  default = "index.handler"
}

variable "memory_size" {
  type    = number
  default = 128

  validation {
    condition     = var.memory_size <= 256
    error_message = "Sandbox: Lambda memory must be <= 256 MB."
  }
}

variable "timeout" {
  type    = number
  default = 10

  validation {
    condition     = var.timeout <= 10
    error_message = "Sandbox: Lambda timeout must be <= 10 seconds."
  }
}
