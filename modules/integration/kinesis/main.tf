resource "aws_kinesis_stream" "this" {
  name             = var.stream_name
  shard_count      = 1
  retention_period = 24

  tags = {
    Name = var.stream_name
    Lab  = "kodekloud"
  }
}
