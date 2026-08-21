output "rest_api_id" {
  value = aws_api_gateway_rest_api.this.id
}

output "invoke_url" {
  value = "${aws_api_gateway_stage.dev.invoke_url}/"
}

output "stage_name" {
  value = aws_api_gateway_stage.dev.stage_name
}
