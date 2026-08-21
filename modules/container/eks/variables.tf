variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "cluster_name" {
  type    = string
  default = "kk-lab-eks"
}

variable "cluster_version" {
  type    = string
  default = "1.36"
}

# IAM role (from the iam-vpc module) granted cluster-admin via an EKS access entry.
variable "cluster_admin_role_name" {
  type        = string
  default     = "kk-lab-lab-role"
  description = "Name of the IAM role to grant EKS cluster-admin access (created by the iam-vpc module)."
}

variable "create_access_entry" {
  type        = bool
  default     = true
  description = "Create an EKS access entry + cluster-admin policy association for the lab role. Set false if the playground IAM policy blocks eks:CreateAccessEntry."
}

# Playground provides these roles; referenced by name.
variable "cluster_role_name" {
  type    = string
  default = "eksClusterRole"
}

variable "node_role_name" {
  type    = string
  default = "AmazonEKSNodeRole"
}

variable "node_instance_type" {
  type    = string
  default = "t3.micro"

  validation {
    condition     = can(regex("^t[23]\\.(nano|micro|small|medium)$", var.node_instance_type))
    error_message = "Allowed node types: t2/t3 nano|micro|small|medium."
  }
}

variable "node_desired" {
  type    = number
  default = 1
}
