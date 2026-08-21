resource "aws_secretsmanager_secret" "this" {
  name                    = "${var.name_prefix}-secret"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.name_prefix}-secret"
    Lab  = "kodekloud"
  }
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    username = "kodekloud"
    password = var.secret_password
  })
}
