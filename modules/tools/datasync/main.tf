resource "aws_s3_bucket" "this" {
  bucket        = "${var.name_prefix}-datasync-${var.random_suffix}"
  force_destroy = true

  tags = {
    Name = "${var.name_prefix}-datasync"
    Lab  = "kodekloud"
  }
}

data "aws_iam_policy_document" "assume_datasync" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["datasync.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "datasync" {
  name               = "${var.name_prefix}-datasync"
  assume_role_policy = data.aws_iam_policy_document.assume_datasync.json

  tags = {
    Lab = "kodekloud"
  }
}

resource "aws_iam_role_policy_attachment" "datasync" {
  role       = aws_iam_role.datasync.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataSyncServiceRole"
}

resource "aws_datasync_location_s3" "source" {
  s3_bucket_arn = aws_s3_bucket.this.arn
  subdirectory  = "/source"
  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync.arn
  }
}

resource "aws_datasync_location_s3" "destination" {
  s3_bucket_arn = aws_s3_bucket.this.arn
  subdirectory  = "/dest"
  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync.arn
  }
}

resource "aws_datasync_task" "this" {
  source_location_arn      = aws_datasync_location_s3.source.arn
  destination_location_arn = aws_datasync_location_s3.destination.arn
  name                     = "${var.name_prefix}-task"

  tags = {
    Name = "${var.name_prefix}-task"
    Lab  = "kodekloud"
  }
}
