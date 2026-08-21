variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "kk-lab"
}

variable "instance_type" {
  description = "EC2 instance type (sandbox allows t2/t3 nano/micro/small/medium)"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^t[23]\\.(nano|micro|small|medium)$", var.instance_type))
    error_message = "Only t2/t3 nano|micro|small|medium are allowed in the sandbox."
  }
}

variable "subnet_id" {
  description = "Subnet to launch in. Falls back to default VPC subnet if empty."
  type        = string
  default     = ""
}

variable "associate_public_ip" {
  description = "Associate a public IP (needed for internet access from the instance)"
  type        = bool
  default     = true
}
