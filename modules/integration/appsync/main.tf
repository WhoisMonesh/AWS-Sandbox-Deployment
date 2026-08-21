resource "aws_appsync_graphql_api" "this" {
  name                = var.api_name
  authentication_type = "API_KEY"

  tags = {
    Name = var.api_name
    Lab  = "kodekloud"
  }
}

resource "aws_appsync_api_key" "this" {
  api_id  = aws_appsync_graphql_api.this.id
  expires = timeadd(timestamp(), "8760h")
}
