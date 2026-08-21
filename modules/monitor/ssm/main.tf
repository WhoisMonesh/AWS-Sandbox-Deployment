resource "aws_ssm_parameter" "this" {
  name  = var.parameter_name
  type  = var.parameter_type
  value = var.parameter_value

  tags = {
    Lab = "kodekloud"
  }
}

resource "aws_ssm_document" "this" {
  name          = var.document_name
  document_type = "Command"
  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Run a shell script on KodeKloud lab instances"
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "run"
        inputs = {
          runCommand = ["echo hello from kodekloud"]
        }
      }
    ]
  })

  tags = {
    Lab = "kodekloud"
  }
}
