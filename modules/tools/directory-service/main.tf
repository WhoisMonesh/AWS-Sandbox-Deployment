data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

resource "aws_directory_service_directory" "this" {
  name     = var.directory_name
  password = var.directory_password
  type     = "SimpleAD"
  size     = "Small"

  vpc_settings {
    vpc_id     = data.aws_vpc.default.id
    subnet_ids = slice(data.aws_subnets.default.ids, 0, 2)
  }

  tags = {
    Name = var.directory_name
    Lab  = "kodekloud"
  }
}
