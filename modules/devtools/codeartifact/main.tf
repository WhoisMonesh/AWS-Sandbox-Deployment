resource "aws_codeartifact_domain" "this" {
  domain = var.domain_name

  tags = {
    Lab = "kodekloud"
  }
}

resource "aws_codeartifact_repository" "this" {
  repository = var.repository_name
  domain     = aws_codeartifact_domain.this.domain

  tags = {
    Lab = "kodekloud"
  }
}
