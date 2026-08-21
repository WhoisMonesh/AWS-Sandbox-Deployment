resource "aws_redshiftserverless_namespace" "this" {
  namespace_name      = var.namespace_name
  db_name             = var.db_name
  admin_username      = var.admin_username
  admin_user_password = var.admin_password

  tags = {
    Name = var.namespace_name
    Lab  = "kodekloud"
  }
}

resource "aws_redshiftserverless_workgroup" "this" {
  namespace_name      = aws_redshiftserverless_namespace.this.namespace_name
  workgroup_name      = var.workgroup_name
  base_capacity       = 8
  publicly_accessible = false

  tags = {
    Name = var.workgroup_name
    Lab  = "kodekloud"
  }
}
