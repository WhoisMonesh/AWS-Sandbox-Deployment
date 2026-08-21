locals {
  artifact_bucket = "${var.name_prefix}-synthetics-${var.random_suffix}"
}

resource "aws_s3_bucket" "artifacts" {
  bucket        = local.artifact_bucket
  force_destroy = true

  tags = {
    Name = local.artifact_bucket
    Lab  = "kodekloud"
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_synthetics_canary" "this" {
  name                 = var.canary_name
  artifact_s3_location = "${aws_s3_bucket.artifacts.id}/"
  runtime_version      = var.runtime
  zip_file             = var.script_zip
  handler              = var.handler
  start_canary         = false

  execution_role_arn = aws_iam_role.canary.arn

  schedule {
    expression = "rate(5 minutes)"
  }

  tags = {
    Lab = "kodekloud"
  }
}

data "aws_iam_policy_document" "assume_canary" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "canary" {
  name               = "${var.name_prefix}-canary-role"
  assume_role_policy = data.aws_iam_policy_document.assume_canary.json

  tags = {
    Lab = "kodekloud"
  }
}

resource "aws_iam_role_policy_attachment" "canary" {
  role       = aws_iam_role.canary.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
