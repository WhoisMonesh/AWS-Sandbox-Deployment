output "rule_name" {
  description = "Name of the X-Ray sampling rule"
  value       = aws_xray_sampling_rule.this.rule_name
}

output "arn" {
  description = "ARN of the X-Ray sampling rule"
  value       = aws_xray_sampling_rule.this.arn
}
