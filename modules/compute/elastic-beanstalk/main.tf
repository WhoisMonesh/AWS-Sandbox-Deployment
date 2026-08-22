resource "aws_elastic_beanstalk_application" "this" {
  name        = var.application_name
  description = "KodeKloud Elastic Beanstalk application"

  tags = {
    Lab = "kodekloud"
  }
}

resource "aws_elastic_beanstalk_application_version" "this" {
  name        = var.application_version_label
  application = aws_elastic_beanstalk_application.this.name
  description = "Initial application version"

  bucket = var.s3_bucket
  key    = var.s3_key

  depends_on = [aws_elastic_beanstalk_application.this]
}

resource "aws_elastic_beanstalk_environment" "this" {
  name                = "${var.name_prefix}-env"
  application         = aws_elastic_beanstalk_application.this.name
  solution_stack_name = var.solution_stack_name
  version_label       = aws_elastic_beanstalk_application_version.this.name
  cname_prefix        = var.cname_prefix

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }

  # Pin the size so EB defaults can't drift outside the sandbox's
  # t2/t3 nano|micro|small|medium allow-list.
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
  }

  tags = {
    Lab = "kodekloud"
  }
}
