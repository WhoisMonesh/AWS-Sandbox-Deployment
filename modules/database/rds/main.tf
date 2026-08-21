data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

locals {
  name = "${var.name_prefix}-rds"
  engine_version_map = {
    mysql    = "8.0"
    mariadb  = "10.11"
    postgres = "15"
  }
}

resource "aws_db_subnet_group" "this" {
  name       = local.name
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = local.name
    Lab  = "kodekloud"
  }
}

resource "aws_security_group" "this" {
  name        = "${local.name}-sg"
  description = "Allow MySQL/Postgres inbound from within the VPC"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = var.engine == "postgres" ? 5432 : 3306
    to_port     = var.engine == "postgres" ? 5432 : 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  tags = {
    Name = "${local.name}-sg"
    Lab  = "kodekloud"
  }
}

resource "aws_db_instance" "this" {
  identifier             = local.name
  engine                 = var.engine
  engine_version         = local.engine_version_map[var.engine]
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  storage_type           = "gp2"
  db_name                = "kklabdb"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  skip_final_snapshot    = true
  publicly_accessible    = false

  tags = {
    Name = local.name
    Lab  = "kodekloud"
  }
}
