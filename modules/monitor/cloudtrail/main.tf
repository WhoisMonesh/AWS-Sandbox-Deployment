locals {
  bucket_name = "${var.name_prefix}-cloudtrail-${var.random_suffix}"
}

resource "aws_s3_bucket" "this" {
  bucket        = local.bucket_name
  force_destroy = true

  tags = {
    Name = local.bucket_name
    Lab  = "kodekloud"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudtrail" "this" {
  name                       = var.trail_name
  s3_bucket_name             = aws_s3_bucket.this.id
  is_multi_region_trail      = false
  enable_log_file_validation = true

  tags = {
    Name = var.trail_name
    Lab  = "kodekloud"
  }
}
