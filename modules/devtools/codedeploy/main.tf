data "aws_iam_policy_document" "assume_codedeploy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codedeploy" {
  name               = "${var.name_prefix}-codedeploy"
  assume_role_policy = data.aws_iam_policy_document.assume_codedeploy.json

  tags = {
    Lab = "kodekloud"
  }
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRole"
}

resource "aws_codedeploy_app" "this" {
  name             = "${var.name_prefix}-codedeploy-app"
  compute_platform = "Server"
}

resource "aws_codedeploy_deployment_group" "this" {
  app_name              = aws_codedeploy_app.this.name
  deployment_group_name = var.deployment_group_name
  service_role_arn      = aws_iam_role.codedeploy.arn

  deployment_style {
    deployment_type   = "IN_PLACE"
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
  }

  ec2_tag_set {
    ec2_tag_filter {
      key   = var.ec2_tag_key
      type  = "KEY_AND_VALUE"
      value = var.ec2_tag_value
    }
  }
}
