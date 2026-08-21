resource "aws_kms_key" "this" {
  description             = "${var.name_prefix} key"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name = "${var.name_prefix}-kms"
    Lab  = "kodekloud"
  }
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name_prefix}-kms"
  target_key_id = aws_kms_key.this.key_id
}
