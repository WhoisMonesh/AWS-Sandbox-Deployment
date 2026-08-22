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
  # subnet in an unsupported AZ before handing subnets to the cluster/nodes.
  eks_subnet_ids = [
    for s in data.aws_subnets.default.ids : s
    if data.aws_subnet.selected[s].availability_zone != "us-east-1e"
  ]
  node_instance_profile_name = "${var.name_prefix}-eks-node-profile"
  node_security_group_name   = "${var.name_prefix}-eks-node-sg"
  node_launch_template_name  = "${var.name_prefix}-eks-node-lt"
  node_stack_name            = "${var.name_prefix}-eks-node-stack"
  # EKS-optimized Amazon Linux 2023 AMI for the cluster minor version.
  # Note: the "recommended" alias requires the architecture dimension, e.g.
  # .../amazon-linux-2023/x86_64/standard/recommended/image_id (the flat
  # .../amazon-linux-2023/recommended/image_id path does NOT exist).
  node_ami_ssm_param = "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2023/x86_64/standard/recommended/image_id"
}

# ---------------------------------------------------------------------------
# EKS cluster service role
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "assume_cluster" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
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

# ---------------------------------------------------------------------------
# Worker node IAM role (course role the playground allows PassRole on)
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "assume_node" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
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

resource "aws_iam_role_policy_attachment" "node_ssm" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "node" {
  name = local.node_instance_profile_name
  role = aws_iam_role.node.name

  tags = {
    Name = local.node_instance_profile_name
    Lab  = "kodekloud"
  }
}

# SSH key pair for the worker nodes (lets you SSH in for debugging). Private key
# is written to the repo-root ssh/ directory (gitignored).
resource "tls_private_key" "node" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "node" {
  key_name   = "${var.name_prefix}-eks-node-key"
  public_key = tls_private_key.node.public_key_openssh

  tags = {
    Name = "${var.name_prefix}-eks-node-key"
    Lab  = "kodekloud"
  }
}

resource "local_file" "node_key" {
  content              = tls_private_key.node.private_key_pem
  filename             = "../../ssh/${var.name_prefix}-eks-node.pem"
  file_permission      = "0600"
  directory_permission = "0700"
}

# ---------------------------------------------------------------------------
# Worker node security group + control-plane <-> node rules
# ---------------------------------------------------------------------------
resource "aws_security_group" "node" {
  name        = local.node_security_group_name
  description = "Security group for the EKS worker nodes (kk-lab)"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = local.node_security_group_name
    Lab  = "kodekloud"
  }
}

resource "aws_vpc_security_group_ingress_rule" "node_to_node" {
  description                  = "Allow nodes to communicate with each other"
  security_group_id            = aws_security_group.node.id
  referenced_security_group_id = aws_security_group.node.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_egress_rule" "node_egress_all" {
  description       = "Allow node egress to anywhere"
  security_group_id = aws_security_group.node.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol        = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "node_from_control_plane" {
  description                  = "Allow worker kubelets/pods to receive traffic from the control plane"
  security_group_id            = aws_security_group.node.id
  referenced_security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  from_port                    = 1025
  to_port                      = 65535
  ip_protocol                  = "TCP"
}

resource "aws_vpc_security_group_ingress_rule" "node_from_control_plane_443" {
  description                  = "Allow extension API servers (443) from the control plane"
  security_group_id            = aws_security_group.node.id
  referenced_security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "TCP"
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_from_node" {
  description                  = "Allow pods to reach the API server"
  security_group_id            = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  referenced_security_group_id = aws_security_group.node.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "TCP"
}

resource "aws_vpc_security_group_egress_rule" "control_plane_to_node" {
  description                  = "Allow control plane to reach worker kubelets/pods"
  security_group_id            = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  referenced_security_group_id = aws_security_group.node.id
  from_port                    = 1025
  to_port                      = 65535
  ip_protocol                  = "TCP"
}

resource "aws_vpc_security_group_egress_rule" "control_plane_to_node_443" {
  description                  = "Allow control plane to reach extension API servers"
  security_group_id            = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  referenced_security_group_id = aws_security_group.node.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "TCP"
}

# ---------------------------------------------------------------------------
# EKS control plane
# ---------------------------------------------------------------------------
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  # API_AND_CONFIG_MAP keeps the legacy aws-auth ConfigMap working alongside
  # access entries. bootstrap_cluster_creator_admin_permissions grants the
  # deploying principal cluster-admin so nodes can be joined via aws-auth.
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
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

# ---------------------------------------------------------------------------
# Worker nodes (self-managed) — KodeKloud playground safe
#
# The lab blocks eks:CreateNodegroup, so we launch nodes the way the course does:
# a launch template bootstrapped with /etc/eks/bootstrap.sh, driven by a
# CloudFormation AutoScalingGroup. This avoids the managed node group API while
# still joining real nodes to the cluster.
# ---------------------------------------------------------------------------
data "aws_ssm_parameter" "node_ami" {
  count = var.create_node_group ? 1 : 0
  name  = local.node_ami_ssm_param
}

resource "aws_launch_template" "node" {
  count = var.create_node_group ? 1 : 0

  name          = local.node_launch_template_name
  image_id      = data.aws_ssm_parameter.node_ami[0].value
  instance_type = var.node_instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.node.name
  }

  key_name = aws_key_pair.node.key_name

  vpc_security_group_ids = [aws_security_group.node.id]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      volume_size           = 20
      volume_type           = "gp2"
      encrypted             = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name_prefix}-worker-node"
      Lab  = "kodekloud"
    }
  }

  # AL2023-based EKS AMIs removed bootstrap.sh; nodes are now initialized by
  # nodeadm. Write a NodeConfig and run `nodeadm init` with the cluster details.
  user_data = base64encode(<<-EOT
    #!/bin/bash
    set -o xtrace
    cat > /etc/eks/bootstrap.json <<'BOOTSTRAP'
    {
      "apiVersion": "node.eks.aws/v1alpha1",
      "kind": "NodeConfig",
      "spec": {
        "cluster": {
          "name": "${aws_eks_cluster.this.name}",
          "apiServerEndpoint": "${aws_eks_cluster.this.endpoint}",
          "certificateAuthority": "${aws_eks_cluster.this.certificate_authority[0].data}",
          "cidr": "${aws_eks_cluster.this.kubernetes_network_config[0].service_ipv4_cidr}"
        }
      }
    }
    BOOTSTRAP
    /usr/bin/nodeadm init -c file:///etc/eks/bootstrap.json
  EOT
  )
}

# Wait for the launch template to settle before the ASG references it.
resource "time_sleep" "node_lt" {
  count           = var.create_node_group ? 1 : 0
  depends_on       = [aws_launch_template.node]
  create_duration = "30s"
}

resource "aws_cloudformation_stack" "node" {
  count = var.create_node_group ? 1 : 0

  name = local.node_stack_name
  template_body = jsonencode({
    Description = "Self-managed EKS worker node AutoScalingGroup (kk-lab)"
    Resources = {
      NodeGroup = {
        Type = "AWS::AutoScaling::AutoScalingGroup"
        Properties = {
          VPCZoneIdentifier        = local.eks_subnet_ids
          MinSize                  = var.node_group_min_size
          MaxSize                  = var.node_group_max_size
          DesiredCapacity          = var.node_desired
          HealthCheckType          = "EC2"
          LaunchTemplate = {
            LaunchTemplateId = aws_launch_template.node[0].id
            Version          = aws_launch_template.node[0].latest_version
          }
        }
        UpdatePolicy = {
          AutoScalingRollingUpdate = {
            MaxBatchSize            = 1
            MinInstancesInService   = var.node_desired
              PauseTime               = "PT2M"
          }
        }
      }
    }
    Outputs = {
      NodeAutoScalingGroup = {
        Description = "The worker node autoscaling group"
        Value       = "!Ref NodeGroup"
      }
    }
  })

  depends_on = [time_sleep.node_lt, kubernetes_config_map.aws_auth]
}

# ---------------------------------------------------------------------------
# Join the worker nodes to the cluster via the aws-auth ConfigMap.
#
# The node IAM role is mapped to system:bootstrappers / system:nodes so the
# kubelet can register. This is what `kubectl get nodes` needs and what the
# bastion (which reuses the node role) relies on.
# ---------------------------------------------------------------------------
data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

# In API_AND_CONFIG_MAP auth mode EKS does NOT auto-provision the aws-auth
# ConfigMap, so we create it here and map the node IAM role.
resource "kubernetes_config_map" "aws_auth" {
  count      = var.create_node_group ? 1 : 0
  depends_on = [aws_eks_cluster.this]

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = aws_iam_role.node.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ])
  }
}
