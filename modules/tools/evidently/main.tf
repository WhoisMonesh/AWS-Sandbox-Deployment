resource "aws_evidently_project" "this" {
  name = "${var.name_prefix}-project"

  tags = {
    Name = "${var.name_prefix}-project"
    Lab  = "kodekloud"
  }
}
