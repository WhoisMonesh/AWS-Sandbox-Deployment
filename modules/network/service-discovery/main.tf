data "aws_vpc" "default" {
  default = true
}

locals {
  name = "${var.name_prefix}-sd"
}

resource "aws_service_discovery_private_dns_namespace" "this" {
  name = var.namespace_name
  vpc  = data.aws_vpc.default.id

  tags = {
    Name = local.name
    Lab  = "kodekloud"
  }
}

resource "aws_service_discovery_service" "this" {
  name = var.service_name

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.this.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
