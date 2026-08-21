data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["tasks.apprunner.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name               = "${var.name_prefix}-apprunner"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = {
    Lab = "kodekloud"
  }
}

resource "aws_apprunner_service" "this" {
  service_name = var.service_name

  source_configuration {
    auto_deployments_enabled = true

    image_repository {
      image_identifier      = var.image_identifier
      image_repository_type = "ECR_PUBLIC"

      image_configuration {
        port = "80"
      }
    }
  }

  instance_configuration {
    instance_role_arn = aws_iam_role.instance.arn
  }

  tags = {
    Name = var.service_name
    Lab  = "kodekloud"
  }
}
