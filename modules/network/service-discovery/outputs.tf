output "namespace_id" {
  value = aws_service_discovery_private_dns_namespace.this.id
}

output "service_id" {
  value = aws_service_discovery_service.this.id
}

output "namespace_arn" {
  value = aws_service_discovery_private_dns_namespace.this.arn
}
