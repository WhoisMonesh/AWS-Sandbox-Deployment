resource "aws_rum_app_monitor" "this" {
  name   = var.app_monitor_name
  domain = var.domain

  tags = {
    Name = var.app_monitor_name
    Lab  = "kodekloud"
  }
}
