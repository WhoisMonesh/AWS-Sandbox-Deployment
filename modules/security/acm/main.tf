resource "aws_acm_certificate" "this" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = {
    Name = "${var.name_prefix}-acm"
    Lab  = "kodekloud"
  }

  lifecycle {
    create_before_destroy = true
  }
}
