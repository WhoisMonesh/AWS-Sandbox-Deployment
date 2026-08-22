data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_subnets" "default" {
  count = var.subnet_id == "" ? 1 : 0

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Resolve per-subnet AZ so we can drop unsupported ones (e.g. us-east-1e).
data "aws_subnet" "default_selected" {
  count = var.subnet_id == "" ? length(data.aws_subnets.default[0].ids) : 0
  id    = data.aws_subnets.default[0].ids[count.index]
}

locals {
  # EKS control plane (and t3/t2 instances) are not supported in us-east-1e.
  supported_subnet_ids = var.subnet_id != "" ? [var.subnet_id] : [
    for s in data.aws_subnet.default_selected : s.id
    if s.availability_zone != "us-east-1e"
  ]
  subnet_id = length(local.supported_subnet_ids) > 0 ? local.supported_subnet_ids[0] : var.subnet_id
  name      = "${var.name_prefix}-ec2"
}

resource "aws_instance" "this" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = local.subnet_id
  associate_public_ip_address = var.associate_public_ip

  # Sandbox rule: T-series must be in STANDARD CPU credit mode.
  credit_specification {
    cpu_credits = "standard"
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name = local.name
    Lab  = "kodekloud"
  }

  # Playground terminates instances on stop; avoid accidental destroy surprises.
  lifecycle {
    create_before_destroy = false
  }
}
