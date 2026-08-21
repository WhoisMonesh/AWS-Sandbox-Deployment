data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.name_prefix}-events"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = {
    Lab = "kodekloud"
  }
}

resource "aws_iam_role_policy" "logs" {
  name = "${var.name_prefix}-events-logs"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.this.arn}:*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/events/${var.name_prefix}-eventbridge"
  retention_in_days = 7

  tags = {
    Lab = "kodekloud"
  }
}

resource "aws_cloudwatch_event_rule" "this" {
  name                = var.rule_name
  schedule_expression = var.schedule_expression

  tags = {
    Name = var.rule_name
    Lab  = "kodekloud"
  }
}

resource "aws_cloudwatch_event_target" "this" {
  rule      = aws_cloudwatch_event_rule.this.name
  target_id = "${var.name_prefix}-log"
  arn       = aws_cloudwatch_log_group.this.arn
  role_arn  = aws_iam_role.this.arn
}
