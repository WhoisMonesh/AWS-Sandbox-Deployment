locals {
  name = "${var.name_prefix}-ebs"
}

resource "aws_ebs_volume" "this" {
  availability_zone = var.availability_zone
  size              = 20
  type              = "gp2"
  encrypted         = true

  tags = {
    Name = local.name
    Lab  = "kodekloud"
  }
}

resource "aws_ebs_snapshot" "this" {
  volume_id = aws_ebs_volume.this.id

  tags = {
    Name = "${local.name}-snap"
    Lab  = "kodekloud"
  }
}
