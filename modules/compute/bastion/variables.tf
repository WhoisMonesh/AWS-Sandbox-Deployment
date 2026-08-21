variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"

  validation {
    condition     = can(regex("^t[23]\\.(nano|micro|small|medium)$", var.instance_type))
    error_message = "Only t2/t3 nano|micro|small|medium are allowed in the sandbox."
  }
}

variable "cluster_name" {
  type    = string
  default = "kk-lab-eks"
}

# Pinned to the EKS cluster minor version (kubectl must be within one minor of the server).
variable "kubectl_version" {
  type        = string
  default     = "v1.36.0"
  description = "kubectl release to install on the bastion (match the EKS cluster minor version)."
}

# The THREE data sources below are looked up by the tags/names created by the
# iam-vpc module. Deploy iam-vpc (or group-core) before this module.
variable "vpc_name" {
  type    = string
  default = ""
}

variable "public_subnet_name" {
  type    = string
  default = ""
}

variable "lab_instance_profile_name" {
  type    = string
  default = ""
}

variable "ssh_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR allowed to SSH to the bastion. Restrict this in production (e.g. your office IP)."
}

variable "key_name" {
  type    = string
  default = ""
}

# Path (relative to the calling root) where the generated private key is written.
# The repo .gitignore excludes ssh/ and *.pem so the key is never committed.
variable "private_key_filename" {
  type    = string
  default = "ssh/kk-lab-bastion.pem"
}

# Attach a minimal EKS API policy (DescribeCluster / GetToken) to the lab role so
# the bastion can run `aws eks update-kubeconfig` and the kubectl exec plugin.
# Set false if the playground IAM policy blocks iam:PutRolePolicy on the lab role.
variable "grant_eks_api_permissions" {
  type    = bool
  default = true
}
