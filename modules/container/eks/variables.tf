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

# The KodeKloud playground only permits iam:PassRole on the course roles, so the
# cluster and (especially) the worker nodes must use these exact names.
variable "cluster_role_name" {
  type    = string
  default = "eksClusterRole"
}

variable "node_role_name" {
  type    = string
  default = "eksWorkerNodeRole"
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
  default = 2
}

variable "node_group_min_size" {
  type    = number
  default = 1
}

variable "node_group_max_size" {
  type    = number
  default = 3
}

# Set false to skip deploying worker nodes (control plane only).
variable "create_node_group" {
  type        = bool
  default     = true
  description = "Provision self-managed worker nodes (CFN ASG + bootstrap.sh). Mirrors the KodeKloud course workflow; avoids eks:CreateNodegroup which the lab blocks."
}
