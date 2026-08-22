data "aws_caller_identity" "current" {}

locals {
  # S3 bucket names are globally unique, so they must differ across lab
  # sessions (each session is a fresh account). Default to the account id,
  # which is unique per account and stable within a session. Override with
  # var.random_suffix if you need a specific name.
  bucket_name = "${var.name_prefix}-s3-${coalesce(var.random_suffix, data.aws_caller_identity.current.account_id)}"
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
  count                   = var.enable_extras ? 1 : 0
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  count  = var.enable_extras ? 1 : 0
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Sandbox policy requires standard encryption on all S3 buckets, so this is
# unconditional (not gated behind enable_extras like versioning/public-block).
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
