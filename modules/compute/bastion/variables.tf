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

# The bastion reuses the worker node IAM role / instance profile created by the
# eks module. The node role is mapped to system:nodes in the aws-auth ConfigMap,
# so kubectl (get nodes, logs, exec) works from the bastion. The playground only
# permits iam:PassRole on the course role, so we must reuse it (not a custom role).
variable "node_instance_profile_name" {
  type    = string
  default = "kk-lab-eks-node-profile"
}

variable "node_role_name" {
  type        = string
  default     = "eksWorkerNodeRole"
  description = "Worker node IAM role (created by the eks module) the bastion reuses."
}

# The VPC / subnet the eks module launched the node group into (default VPC). The
# bastion lives in the same VPC so it can reach the cluster API + nodes.
variable "vpc_name" {
  type    = string
  default = ""
}

variable "public_subnet_name" {
  type    = string
  default = ""
}

variable "ssh_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR allowed to SSH to the bastion (used when restrict_ssh_to_operator_ip = false)."
}

# Restrict SSH to the public IP of the machine running Terraform (your server),
# detected at plan time. This is the recommended setting so the bastion is not
# reachable from 0.0.0.0/0.
variable "restrict_ssh_to_operator_ip" {
  type        = bool
  default     = true
  description = "Lock SSH ingress to the operator's public IP (/32) instead of ssh_cidr."
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

# Attach eks:DescribeCluster / ListClusters / sts:GetCallerIdentity to the node
# role so the bastion can run `aws eks update-kubeconfig`. Set false if the lab
# IAM policy blocks iam:PutRolePolicy on the node (course) role.
variable "attach_jump_policy" {
  type    = bool
  default = true
}
