locals {
  name = "${var.name_prefix}-internet-monitor"
}

resource "aws_internetmonitor_monitor" "this" {
  monitor_name                  = local.name
  status                        = var.monitor_status
  traffic_percentage_to_monitor = 100

  health_events_config {
    availability_score_threshold = 99.9
    performance_score_threshold  = 99.9
  }

  tags = {
    Name = local.name
    Lab  = "kodekloud"
  }
}
