output "api_id" {
  value = aws_appsync_graphql_api.this.id
}

output "api_arn" {
  value = aws_appsync_graphql_api.this.arn
}

output "api_key" {
  value     = aws_appsync_api_key.this.key
  sensitive = true
}
