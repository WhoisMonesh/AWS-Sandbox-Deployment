output "table_name" {
  value = aws_dynamodb_table.this.name
}

output "target_id" {
  value = aws_appautoscaling_target.write.id
}
