output "parameter_name" {
  description = "Name of the SSM parameter"
  value       = aws_ssm_parameter.this.name
}

output "document_name" {
  description = "Name of the SSM document"
  value       = aws_ssm_document.this.name
}
