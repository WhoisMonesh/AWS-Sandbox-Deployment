output "application_id" {
  description = "ID of the Application Insights application"
  value       = aws_applicationinsights_application.this.id
}
