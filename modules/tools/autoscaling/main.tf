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

data "aws_subnets" "default" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

resource "aws_launch_template" "this" {
  name_prefix   = "${var.name_prefix}-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  credit_specification {
    cpu_credits = "standard"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_type           = "gp2"
      volume_size           = 20
      encrypted             = true
      delete_on_termination = true
    }
  }

  tags = {
    Name = "${var.name_prefix}-lt"
    Lab  = "kodekloud"
  }
}

resource "aws_autoscaling_group" "this" {
  name     = "${var.name_prefix}-asg"
  min_size = 1
  # KodeKloud caps: 5 total EC2 instances and 10 vCPU account-wide. With the
  # EKS node group (2x t3.micro) + bastion (t3.micro) already running, an ASG
  # scale-out beyond 1 extra instance breaches both. Keep max at 2.
  max_size            = 2
  desired_capacity    = 1
  vpc_zone_identifier = data.aws_subnets.default.ids

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-asg"
    propagate_at_launch = true
  }
  tag {
    key                 = "Lab"
    value               = "kodekloud"
    propagate_at_launch = true
  }
}
