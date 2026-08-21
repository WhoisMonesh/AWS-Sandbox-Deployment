data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_iam_policy_document" "assume_imagebuilder" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "imagebuilder" {
  name               = "${var.name_prefix}-imagebuilder"
  assume_role_policy = data.aws_iam_policy_document.assume_imagebuilder.json

  tags = {
    Lab = "kodekloud"
  }
}

resource "aws_iam_role_policy_attachment" "imagebuilder" {
  role       = aws_iam_role.imagebuilder.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
}

resource "aws_iam_instance_profile" "imagebuilder" {
  name = "${var.name_prefix}-imagebuilder-profile"
  role = aws_iam_role.imagebuilder.name
}

resource "aws_security_group" "imagebuilder" {
  name   = "${var.name_prefix}-imagebuilder-sg"
  vpc_id = data.aws_vpc.default.id

  tags = {
    Lab = "kodekloud"
  }
}

resource "aws_imagebuilder_infrastructure_configuration" "this" {
  name                  = "${var.name_prefix}-infra"
  instance_types        = [var.instance_type]
  instance_profile_name = aws_iam_instance_profile.imagebuilder.name
  security_group_ids    = [aws_security_group.imagebuilder.id]
  subnet_id             = data.aws_subnets.default.ids[0]

  tags = {
    Lab = "kodekloud"
  }
}

resource "aws_imagebuilder_component" "this" {
  name     = var.component_name
  platform = "Linux"
  version  = "1.0.0"

  data = yamlencode({
    schemaVersion = 1.0
    phases = [{
      name = "build"
      steps = [{
        name      = "UpdateOS"
        action    = "UpdateOS"
        onFailure = "Continue"
      }]
    }]
  })

  tags = {
    Lab = "kodekloud"
  }
}

resource "aws_imagebuilder_image_recipe" "this" {
  name         = var.recipe_name
  version      = var.recipe_version
  parent_image = data.aws_ami.amazon_linux.id

  component {
    component_arn = aws_imagebuilder_component.this.arn
  }

  tags = {
    Lab = "kodekloud"
  }
}
