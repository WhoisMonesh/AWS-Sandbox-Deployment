locals {
  name = "${var.name_prefix}-route53"
}

resource "aws_route53_zone" "this" {
  name = var.domain_name

  tags = {
    Name = local.name
    Lab  = "kodekloud"
  }
}
