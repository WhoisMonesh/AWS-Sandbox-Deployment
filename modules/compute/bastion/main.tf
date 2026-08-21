locals {
  vpc_name                = var.vpc_name == "" ? "${var.name_prefix}-vpc" : var.vpc_name
  public_subnet_name      = var.public_subnet_name == "" ? "${var.name_prefix}-public-subnet" : var.public_subnet_name
  lab_instance_profile    = var.lab_instance_profile_name == "" ? "${var.name_prefix}-lab-profile" : var.lab_instance_profile_name
  key_name                = var.key_name == "" ? "${var.name_prefix}-bastion-key" : var.key_name
  user_data_template_vars = {
    kubectl_version = var.kubectl_version
    region          = var.region
    cluster_name    = var.cluster_name
  }
}

# ----- Look up the lab VPC / subnet / instance profile created by the iam-vpc module -----
data "aws_vpc" "lab" {
  filter {
    name   = "tag:Name"
    values = [local.vpc_name]
  }
}

data "aws_subnet" "public" {
  filter {
    name   = "tag:Name"
    values = [local.public_subnet_name]
  }
}

data "aws_iam_instance_profile" "lab" {
  name = local.lab_instance_profile
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ----- SSH key pair (RSA) -----
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = local.key_name
  public_key = tls_private_key.this.public_key_openssh

  tags = {
    Name = local.key_name
    Lab  = "kodekloud"
  }
}

# Persist the private key locally so the user can SSH (gitignored).
resource "local_file" "private_key" {
  content              = tls_private_key.this.private_key_pem
  filename             = var.private_key_filename
  file_permission      = "0600"
  directory_permission = "0700"
}

# ----- Security group: SSH in, all egress out -----
resource "aws_security_group" "bastion" {
  name        = "${var.name_prefix}-bastion-sg"
  description = "SSH access to the KodeKloud EKS bastion host"
  vpc_id      = data.aws_vpc.lab.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-bastion-sg"
    Lab  = "kodekloud"
  }
}

# ----- Grant the lab role the AWS-side EKS API perms the bastion needs -----
# (The EKS access entry covers Kubernetes RBAC; this covers the AWS API calls
#  like eks:DescribeCluster / eks:GetToken used by update-kubeconfig + kubectl.)
data "aws_iam_policy_document" "eks_api" {
  statement {
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters",
      "eks:GetToken",
      "eks:DescribeClusterVersions",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "eks_api" {
  count = var.grant_eks_api_permissions ? 1 : 0

  name = "${var.name_prefix}-bastion-eks-api"
  role = data.aws_iam_instance_profile.lab.role_name
  policy = data.aws_iam_policy_document.eks_api.json
}

# ----- Bastion instance -----
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  iam_instance_profile        = data.aws_iam_instance_profile.lab.name
  associate_public_ip_address = true
  key_name                    = aws_key_pair.this.key_name

  # Sandbox rule: T-series must be in STANDARD CPU credit mode.
  credit_specification {
    cpu_credits = "standard"
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", local.user_data_template_vars))

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${var.name_prefix}-bastion"
    Lab  = "kodekloud"
  }

  lifecycle {
    create_before_destroy = false
  }
}
