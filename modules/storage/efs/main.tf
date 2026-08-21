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

locals {
  name = "${var.name_prefix}-efs"
}

resource "aws_efs_file_system" "this" {
  creation_token   = local.name
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true

  lifecycle_policy {
    transition_to_ia = "AFTER_1_DAY"
  }

  tags = {
    Name = local.name
    Lab  = "kodekloud"
  }
}

resource "aws_efs_mount_target" "this" {
  file_system_id = aws_efs_file_system.this.id
  subnet_id      = data.aws_subnets.default.ids[0]
}
