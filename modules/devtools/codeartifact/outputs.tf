output "domain_name" {
  value = aws_codeartifact_domain.this.domain
}

output "repository_arn" {
  value = aws_codeartifact_repository.this.arn
}
