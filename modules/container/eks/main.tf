data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Per-AZ details for each default subnet so we can exclude unsupported ones.
data "aws_subnet" "selected" {
  for_each = toset(data.aws_subnets.default.ids)
  id       = each.value
}

locals {
  # EKS control plane does not support every AZ (e.g. us-east-1e). Drop any
  # subnet in an unsupported AZ before handing subnets to the cluster/nodegroup.
  eks_subnet_ids = [
    for s in data.aws_subnets.default.ids : s
    if data.aws_subnet.selected[s].availability_zone != "us-east-1e"
  ]
}

# The playground docs reference eksClusterRole / AmazonEKSNodeRole, but they are
# not always pre-provisioned. Create them so this module is self-contained.
data "aws_iam_policy_document" "assume_cluster" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "assume_node" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = var.cluster_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_cluster.json

  tags = {
    Name = var.cluster_role_name
    Lab  = "kodekloud"
  }
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "node" {
  name               = var.node_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_node.json

  tags = {
    Name = var.node_role_name
    Lab  = "kodekloud"
  }
}

resource "aws_iam_role_policy_attachment" "node_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  # API_AND_CONFIG_MAP lets us grant cluster access via EKS access entries
  # (used by the bastion host) while keeping the legacy aws-auth ConfigMap.
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  vpc_config {
    subnet_ids             = local.eks_subnet_ids
    endpoint_public_access = true
  }

  tags = {
    Name = var.cluster_name
    Lab  = "kodekloud"
  }

  depends_on = [aws_iam_role_policy_attachment.cluster_policy]
}

# The lab IAM role (created by the iam-vpc module / group-core) is granted
# cluster-admin via an EKS access entry so the bastion host can run kubectl.
# This relies on the lab role existing (iam-vpc runs before eks in group-core).
data "aws_iam_role" "lab" {
  name = var.cluster_admin_role_name
}

resource "aws_eks_access_entry" "lab" {
  count         = var.create_access_entry ? 1 : 0
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = data.aws_iam_role.lab.arn
  type          = "STANDARD"

  depends_on = [aws_eks_cluster.this]
}

resource "aws_eks_access_policy_association" "lab" {
  count         = var.create_access_entry ? 1 : 0
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = data.aws_iam_role.lab.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.lab]
}

# NOTE: The playground IAM policy (AWS_EKSECSWithConditions) does not permit
# eks:CreateNodegroup, and also blocks the prerequisites for a Fargate profile
# (iam:PassRole to eks-fargate-pods.amazonaws.com and iam:PutRolePolicy /
# AttachRolePolicy for AmazonEKSFargatePodExecutionRole). Only eks:CreateCluster
# is allowed, so this module deploys the control plane only. The node IAM role
# below is retained (it was already created) but no managed node group / Fargate
# profile is provisioned under this lab policy.

