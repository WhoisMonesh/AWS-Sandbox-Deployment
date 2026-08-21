resource "aws_cloudformation_stack" "this" {
  name = "${var.name_prefix}-stack"
  template_body = jsonencode({
    Resources = {
      LabBucket = {
        Type = "AWS::S3::Bucket"
        Properties = {
          BucketName = "${var.name_prefix}-cf-${var.random_suffix}"
        }
      }
    }
  })

  tags = {
    Lab = "kodekloud"
  }
}
