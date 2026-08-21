data "aws_iam_policy_document" "assume_lambda" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name_prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json

  tags = {
    Lab = "kodekloud"
  }
}

resource "aws_iam_role_policy_attachment" "basic_exec" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "code" {
  type        = "zip"
  source_file = "${path.module}/index.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  filename         = data.archive_file.code.output_path
  source_code_hash = data.archive_file.code.output_base64sha256
  runtime          = var.runtime
  handler          = var.handler
  memory_size      = var.memory_size
  timeout          = var.timeout
  role             = aws_iam_role.lambda.arn

  tags = {
    Name = var.function_name
    Lab  = "kodekloud"
  }
}
