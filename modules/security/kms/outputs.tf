output "key_id" {
  value = aws_kms_key.this.key_id
}

output "alias_arn" {
  value = aws_kms_alias.this.arn
}
