output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.this.name
}

output "alarm_arn" {
  description = "ARN of the CloudWatch metric alarm"
  value       = aws_cloudwatch_metric_alarm.this.arn
}
