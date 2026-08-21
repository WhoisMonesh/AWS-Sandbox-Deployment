output "monitor_arn" {
  value = aws_internetmonitor_monitor.this.arn
}

output "monitor_name" {
  value = aws_internetmonitor_monitor.this.monitor_name
}
