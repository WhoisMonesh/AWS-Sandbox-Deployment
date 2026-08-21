locals {
  definition = jsonencode({
    Comment = "Minimal state machine"
    StartAt = "Pass"
    States = {
      Pass = {
        Type = "Pass"
        End  = true
      }
    }
  })
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.name_prefix}-sfn"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = {
    Lab = "kodekloud"
  }
}

resource "aws_iam_role_policy" "logging" {
  name = "${var.name_prefix}-sfn-logging"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutResourcePolicy",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["sts:AssumeRole"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/vendedlogs/states/${var.name_prefix}-sfn"
  retention_in_days = 7

  tags = {
    Lab = "kodekloud"
  }
}

resource "aws_sfn_state_machine" "this" {
  name       = var.state_machine_name
  role_arn   = aws_iam_role.this.arn
  type       = "STANDARD"
  definition = local.definition

  logging_configuration {
    level                  = "ALL"
    include_execution_data = true
    log_destination        = "${aws_cloudwatch_log_group.this.arn}:*"
  }

  tags = {
    Name = var.state_machine_name
    Lab  = "kodekloud"
  }
}
