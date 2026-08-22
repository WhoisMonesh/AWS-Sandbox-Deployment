locals {
  key_name = var.key_name == "" ? "${var.name_prefix}-bastion-key" : var.key_name
  user_data_template_vars = {
    kubectl_version = var.kubectl_version
    region          = var.region
    cluster_name    = var.cluster_name
  }
}

# ----- Look up the DEFAULT VPC / subnet the EKS node group lives in -----
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Resolve per-subnet AZ so we can drop unsupported ones (e.g. us-east-1e).
data "aws_subnet" "default_selected" {
  count = length(data.aws_subnets.default.ids)
  id    = data.aws_subnets.default.ids[count.index]
}

locals {
  # EKS / t3 instances are not supported in us-east-1e.
  supported_subnet_ids = [
    for s in data.aws_subnet.default_selected : s.id
    if s.availability_zone != "us-east-1e"
  ]
  subnet_id = length(local.supported_subnet_ids) > 0 ? local.supported_subnet_ids[0] : data.aws_subnets.default.ids[0]
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

# The bastion reuses the worker node IAM role / instance profile created by the
# eks module. The node role is mapped to system:nodes in the cluster aws-auth
# ConfigMap, so kubectl works from the bastion.
data "aws_iam_instance_profile" "node" {
  name = var.node_instance_profile_name
}

data "aws_iam_role" "node" {
  name = var.node_role_name
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
  vpc_id      = data.aws_vpc.default.id

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

# ----- Grant the node role the AWS-side EKS API perms the bastion needs -----
# The aws-auth ConfigMap grants Kubernetes RBAC (system:nodes); this inline
# policy covers the AWS API calls eks:DescribeCluster / eks:GetToken used by
# `aws eks update-kubeconfig` + the kubectl exec credential plugin.
data "aws_iam_policy_document" "jump" {
  statement {
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters",
      "eks:GetToken",
      "sts:GetCallerIdentity",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "jump" {
  count = var.attach_jump_policy ? 1 : 0

  name = "${var.name_prefix}-bastion-jump"
  role = data.aws_iam_role.node.name
  policy = data.aws_iam_policy_document.jump.json
}

# ----- Bastion instance -----
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  iam_instance_profile        = data.aws_iam_instance_profile.node.name
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
