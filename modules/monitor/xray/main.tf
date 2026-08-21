resource "aws_xray_sampling_rule" "this" {
  rule_name      = var.rule_name
  priority       = 9999
  fixed_rate     = var.fixed_rate
  reservoir_size = 0
  service_name   = "*"
  resource_arn   = "*"
  service_type   = "*"
  host           = "*"
  url_path       = "*"
  http_method    = "*"
  version        = 1

  tags = {
    Lab = "kodekloud"
  }
}
