output "volume_id" {
  value = aws_ebs_volume.this.id
}

output "snapshot_id" {
  value = aws_ebs_snapshot.this.id
}
