output "id" {
  description = "ID of the RUM app monitor"
  value       = aws_rum_app_monitor.this.id
}

output "app_monitor_arn" {
  description = "ARN of the RUM app monitor"
  value       = aws_rum_app_monitor.this.arn
}
