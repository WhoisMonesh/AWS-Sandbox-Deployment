output "canary_id" {
  description = "ID of the Synthetics canary"
  value       = aws_synthetics_canary.this.id
}

output "arn" {
  description = "ARN of the Synthetics canary"
  value       = aws_synthetics_canary.this.arn
}
