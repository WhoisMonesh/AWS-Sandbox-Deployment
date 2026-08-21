output "recorder_id" {
  description = "ID of the AWS Config configuration recorder"
  value       = aws_config_configuration_recorder.this.id
}
