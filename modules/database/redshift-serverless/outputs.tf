output "namespace_id" {
  value = aws_redshiftserverless_namespace.this.id
}

output "workgroup_id" {
  value = aws_redshiftserverless_workgroup.this.id
}

output "workgroup_arn" {
  value = aws_redshiftserverless_workgroup.this.arn
}
